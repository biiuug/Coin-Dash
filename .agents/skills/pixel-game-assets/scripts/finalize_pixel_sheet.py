#!/usr/bin/env python3
"""Finalize keyed pixel-art animation sheets into transparent RGBA sheets."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

from PIL import Image, UnidentifiedImageError


KEY_THRESHOLD = 36
FRAME_MARGIN = 4


class ValidationError(Exception):
    pass


def parse_hex_rgb(value: str) -> tuple[int, int, int]:
    raw = value.strip().lower()
    if raw.startswith("#"):
        raw = raw[1:]
    if len(raw) != 6:
        raise argparse.ArgumentTypeError("key must be six hex RGB digits")
    try:
        return tuple(int(raw[index : index + 2], 16) for index in (0, 2, 4))
    except ValueError as exc:
        raise argparse.ArgumentTypeError("key must be six hex RGB digits") from exc


def pixel_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return math.sqrt(sum((left - right) ** 2 for left, right in zip(a, b)))


def remove_key(cell: Image.Image, key: tuple[int, int, int]) -> Image.Image:
    keyed = Image.new("RGBA", cell.size)
    pixels = []
    data = cell.tobytes()
    for offset in range(0, len(data), 4):
        red, green, blue, alpha = data[offset : offset + 4]
        is_key = alpha == 0 or pixel_distance((red, green, blue), key) <= KEY_THRESHOLD
        pixels.append((red, green, blue, 0 if is_key else 255))
    keyed.putdata(pixels)
    return keyed


def require_cell_valid(cell: Image.Image, index: int) -> None:
    alpha = cell.getchannel("A")
    if alpha.getbbox() is None:
        raise ValidationError(f"frame {index} has no visible subject")

    transparent = alpha.tobytes().count(0)
    total = cell.width * cell.height
    if transparent / total < 0.10:
        raise ValidationError(f"frame {index} has less than 10% transparent key background")


def fit_cell(cell: Image.Image, frame_width: int, frame_height: int) -> Image.Image:
    alpha = cell.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValidationError("cannot fit empty frame")

    cropped = cell.crop(bbox)
    max_width = frame_width - (FRAME_MARGIN * 2)
    max_height = frame_height - (FRAME_MARGIN * 2)
    if max_width < 1 or max_height < 1:
        raise ValidationError("target frame is too small for required margin")

    scale = min(max_width / cropped.width, max_height / cropped.height)
    fitted_width = max(1, min(max_width, round(cropped.width * scale)))
    fitted_height = max(1, min(max_height, round(cropped.height * scale)))
    fitted = cropped.resize((fitted_width, fitted_height), Image.Resampling.NEAREST)

    target = Image.new("RGBA", (frame_width, frame_height), (0, 0, 0, 0))
    paste_x = (frame_width - fitted_width) // 2
    paste_y = frame_height - FRAME_MARGIN - fitted_height
    target.alpha_composite(fitted, (paste_x, paste_y))
    return target


def quantize_opaque_palette(sheet: Image.Image, colors: int) -> Image.Image:
    alpha = sheet.getchannel("A")
    quantized = sheet.convert("RGB").quantize(
        colors=colors,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    )
    result = quantized.convert("RGBA")
    result.putalpha(alpha)
    return result


def validate_sheet(sheet: Image.Image, frames: int, frame_width: int, frame_height: int, colors: int) -> None:
    expected_size = (frames * frame_width, frame_height)
    if sheet.size != expected_size:
        raise ValidationError(f"output size {sheet.size} does not match expected {expected_size}")

    alpha_values = set(sheet.getchannel("A").tobytes())
    if not alpha_values.issubset({0, 255}):
        raise ValidationError("output alpha must contain only 0 and 255")

    width, height = sheet.size
    for point in ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)):
        if sheet.getpixel(point)[3] != 0:
            raise ValidationError("output sheet corners must be transparent")

    for index in range(frames):
        left = index * frame_width
        frame = sheet.crop((left, 0, left + frame_width, frame_height))
        if frame.getchannel("A").getbbox() is None:
            raise ValidationError(f"output frame {index} is empty")

    opaque_colors = set()
    data = sheet.tobytes()
    for offset in range(0, len(data), 4):
        red, green, blue, alpha = data[offset : offset + 4]
        if alpha == 255:
            opaque_colors.add((red, green, blue))
    if len(opaque_colors) > colors:
        raise ValidationError(f"opaque palette has {len(opaque_colors)} colors, expected at most {colors}")


def finalize_sheet(
    input_path: Path,
    output_path: Path,
    frames: int,
    frame_width: int,
    frame_height: int,
    key: tuple[int, int, int],
    colors: int,
) -> None:
    if frames < 1:
        raise ValidationError("frames must be at least 1")
    if frame_width < 1 or frame_height < 1:
        raise ValidationError("frame dimensions must be at least 1")
    if colors < 1 or colors > 256:
        raise ValidationError("colors must be between 1 and 256")

    try:
        with Image.open(input_path) as image:
            source = image.convert("RGBA")
    except (OSError, UnidentifiedImageError) as exc:
        raise ValidationError(f"could not read input image: {exc}") from exc
    if source.width % frames != 0:
        raise ValidationError(f"source width {source.width} is not divisible by frame count {frames}")

    source_cell_width = source.width // frames
    sheet = Image.new("RGBA", (frames * frame_width, frame_height), (0, 0, 0, 0))

    for index in range(frames):
        left = index * source_cell_width
        source_cell = source.crop((left, 0, left + source_cell_width, source.height))
        keyed_cell = remove_key(source_cell, key)
        require_cell_valid(keyed_cell, index)
        target_cell = fit_cell(keyed_cell, frame_width, frame_height)
        sheet.alpha_composite(target_cell, (index * frame_width, 0))

    sheet = quantize_opaque_palette(sheet, colors)
    validate_sheet(sheet, frames, frame_width, frame_height, colors)

    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(output_path)
    except (OSError, ValueError) as exc:
        raise ValidationError(f"could not write output image: {exc}") from exc


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Finalize a keyed pixel animation sheet.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--frames", type=int, default=4)
    parser.add_argument("--frame-width", type=int, default=64)
    parser.add_argument("--frame-height", type=int, default=96)
    parser.add_argument("--key", type=parse_hex_rgb, default=parse_hex_rgb("ff00ff"))
    parser.add_argument("--colors", type=int, default=32)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    try:
        finalize_sheet(
            input_path=args.input,
            output_path=args.output,
            frames=args.frames,
            frame_width=args.frame_width,
            frame_height=args.frame_height,
            key=args.key,
            colors=args.colors,
        )
    except ValidationError as exc:
        print(f"VALIDATION_ERROR: {exc}", file=sys.stderr)
        return 1

    print("PIXEL_SHEET_VALID")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
