# Pixel Game Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a reusable project-local pixel-art generation skill and use it to produce a validated 256 by 96 Warden sample sheet with idle, walk, attack, and hit frames.

**Architecture:** The project skill owns art direction, category dimensions, prompt constraints, and validation rules. Image generation produces a high-resolution four-pose source on a flat chroma key; a deterministic Pillow finalizer removes the background, normalizes each pose into a 64 by 96 frame, quantizes without dithering, and validates the resulting production PNG.

**Tech Stack:** Codex project skills, built-in image generation, Python 3, Pillow, PNG RGBA, Godot 4 nearest-neighbor textures.

---

## File Structure

- `.agents/skills/pixel-game-assets/SKILL.md`: Trigger and workflow for every generated game visual.
- `.agents/skills/pixel-game-assets/agents/openai.yaml`: Skill-list metadata and invocation prompt.
- `.agents/skills/pixel-game-assets/assets/knight-style-reference.gif`: Stable local copy of the supplied style reference.
- `.agents/skills/pixel-game-assets/scripts/finalize_pixel_sheet.py`: Deterministic chroma removal, frame fitting, palette reduction, and PNG validation.
- `tests/validate_pixel_game_assets_skill.ps1`: Executable structural test for the project skill.
- `assets/characters/warden-pixel-sample-source.png`: Generated, keyed source retained for reproducibility.
- `assets/characters/warden-pixel-sample.png`: Final transparent 256 by 96 sample sheet.

### Task 1: Write The Failing Skill Contract Test

**Files:**
- Create: `tests/validate_pixel_game_assets_skill.ps1`

- [ ] **Step 1: Add the structural test before creating the skill**

```powershell
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$skill = Join-Path $root '.agents\skills\pixel-game-assets\SKILL.md'
$finalizer = Join-Path $root '.agents\skills\pixel-game-assets\scripts\finalize_pixel_sheet.py'
$reference = Join-Path $root '.agents\skills\pixel-game-assets\assets\knight-style-reference.gif'

if (-not (Test-Path -LiteralPath $skill)) { throw 'Missing pixel-game-assets SKILL.md' }
if (-not (Test-Path -LiteralPath $finalizer)) { throw 'Missing pixel sheet finalizer' }
if (-not (Test-Path -LiteralPath $reference)) { throw 'Missing local style reference' }

$body = Get-Content -LiteralPath $skill -Raw
foreach ($required in @(
    'Use when generating or editing any',
    '64 by 96',
    'nearest-neighbor',
    'no antialiasing',
    'transparent',
    'characters',
    'enemies',
    'buildings',
    'cards',
    'resources'
)) {
    if (-not $body.Contains($required)) { throw "Missing skill contract: $required" }
}

'PIXEL_GAME_ASSETS_SKILL_TEST_PASS'
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\validate_pixel_game_assets_skill.ps1
```

Expected: failure with `Missing pixel-game-assets SKILL.md`.

- [ ] **Step 3: Commit the failing contract test**

```powershell
git add tests/validate_pixel_game_assets_skill.ps1
git commit -m "test: define pixel asset skill contract"
```

### Task 2: Create The Project-Local Skill

**Files:**
- Create: `.agents/skills/pixel-game-assets/SKILL.md`
- Create: `.agents/skills/pixel-game-assets/agents/openai.yaml`
- Create: `.agents/skills/pixel-game-assets/assets/knight-style-reference.gif`

- [ ] **Step 1: Scaffold the skill**

Run:

```powershell
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'C:\Users\cynth\.codex\skills\.system\skill-creator\scripts\init_skill.py' pixel-game-assets --path .agents\skills --resources scripts,assets --interface 'display_name=Pixel Game Assets' --interface 'short_description=Consistent pixel art for this game' --interface 'default_prompt=Use $pixel-game-assets to generate a game-ready pixel asset.'
```

Expected: `.agents/skills/pixel-game-assets/` contains `SKILL.md`, `agents/openai.yaml`, `scripts/`, and `assets/`.

- [ ] **Step 2: Replace SKILL.md with the approved concise contract**

```markdown
---
name: pixel-game-assets
description: Use when generating or editing any image, sprite, animation, icon, character, enemy, building, card, relic, resource, equipment, background, or other visual asset for Idle Hero Camp.
---

# Pixel Game Assets

## Core Rule

Every generated visual for this game must be crisp pixel art. Use hard pixel edges, a controlled palette, readable silhouettes, nearest-neighbor scaling, no antialiasing, no painterly detail, and no smooth vector rendering.

Use `assets/knight-style-reference.gif` as the primary style reference: compact heroic proportions, dark outlines, clustered highlights, and strong material readability.

## Asset Contract

| Asset | Logical size |
|---|---:|
| Character frame | 64 by 96 |
| Enemy frame | 96 by 96 |
| Building level | 256 by 192 |
| Card illustration | 192 by 108 |
| Resource/equipment icon | 64 by 64 |
| Talent/stage icon | 48 by 48 |

Animation sheets use equal cells, a stable baseline, identical identity and scale, and explicit frame order. Character samples use idle, walk, attack, hit.

## Workflow

1. Inspect existing game assets and this skill's reference before prompting.
2. Generate one subject or one animation sheet at a time with the built-in image tool. Request a flat chroma-key background, no shadows, no text, and no borders.
3. Keep a versioned keyed source. Never overwrite a live asset unless explicitly requested.
4. Run `scripts/finalize_pixel_sheet.py` for sheets. It removes the key, fits each subject to its cell, quantizes without dithering, and writes transparent RGBA.
5. Validate exact dimensions, binary alpha, transparent corners, nonempty cells, limited palette, and visual consistency.
6. Save final project assets under `assets/` and configure Godot textures for nearest-neighbor filtering.

## Common Mistakes

- Pixel-styled high-resolution painting is not pixel art: finalize and inspect at 1x.
- Do not mix frame sizes, baselines, palettes, light direction, or character proportions.
- Do not leave chroma color, soft alpha fringes, labels, borders, scenery, or unrelated objects.
- Do not stretch generated art to fit. Crop, fit proportionally, and center it.
```

- [ ] **Step 3: Copy the user reference into the skill**

```powershell
Copy-Item -LiteralPath 'C:\Users\cynth\OneDrive\桌面\original-8b8b4deb9d26655bd3421d7e18189488.gif' -Destination '.agents\skills\pixel-game-assets\assets\knight-style-reference.gif'
```

- [ ] **Step 4: Validate GREEN**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\validate_pixel_game_assets_skill.ps1
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'C:\Users\cynth\.codex\skills\.system\skill-creator\scripts\quick_validate.py' .agents\skills\pixel-game-assets
```

Expected: `PIXEL_GAME_ASSETS_SKILL_TEST_PASS` and `Skill is valid!`.

- [ ] **Step 5: Commit the skill foundation**

```powershell
git add .agents/skills/pixel-game-assets tests/validate_pixel_game_assets_skill.ps1
git commit -m "feat: add project pixel asset skill"
```

### Task 3: Add The Deterministic Sheet Finalizer

**Files:**
- Create: `.agents/skills/pixel-game-assets/scripts/finalize_pixel_sheet.py`

- [ ] **Step 1: Implement the finalizer**

```python
import argparse
from pathlib import Path

from PIL import Image


def parse_color(value: str) -> tuple[int, int, int]:
    cleaned = value.removeprefix("#")
    if len(cleaned) != 6:
        raise argparse.ArgumentTypeError("key must be six hexadecimal digits")
    return tuple(int(cleaned[index:index + 2], 16) for index in (0, 2, 4))


def remove_key(image: Image.Image, key: tuple[int, int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    threshold_sq = 36 * 36
    alpha = Image.new("L", rgba.size)
    alpha.putdata([
        0 if (r - key[0]) ** 2 + (g - key[1]) ** 2 + (b - key[2]) ** 2 <= threshold_sq else 255
        for r, g, b, _ in rgba.getdata()
    ])
    if alpha.getbbox() is None:
        raise ValueError("source cell is empty after chroma removal")
    transparent = sum(1 for value in alpha.getdata() if value == 0)
    if transparent < alpha.width * alpha.height // 10:
        raise ValueError("source cell does not contain enough chroma-key background")
    rgba.putalpha(alpha)
    return rgba


def fit_frame(source: Image.Image, width: int, height: int) -> Image.Image:
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("source cell has no visible subject")
    subject = source.crop(bbox)
    scale = min((width - 8) / subject.width, (height - 8) / subject.height)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.NEAREST)
    frame = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    frame.alpha_composite(subject, ((width - size[0]) // 2, height - 4 - size[1]))
    return frame


def validate(sheet: Image.Image, frames: int, width: int, height: int, colors: int) -> None:
    if sheet.size != (frames * width, height):
        raise ValueError(f"wrong sheet size: {sheet.size}")
    alpha_values = set(sheet.getchannel("A").getdata())
    if not alpha_values.issubset({0, 255}):
        raise ValueError("alpha must be binary")
    corners = [(0, 0), (sheet.width - 1, 0), (0, sheet.height - 1), (sheet.width - 1, sheet.height - 1)]
    if any(sheet.getpixel(point)[3] != 0 for point in corners):
        raise ValueError("sheet corners must be transparent")
    for index in range(frames):
        cell = sheet.crop((index * width, 0, (index + 1) * width, height))
        if cell.getchannel("A").getbbox() is None:
            raise ValueError(f"frame {index} is empty")
    opaque_colors = {
        (r, g, b)
        for r, g, b, a in sheet.getdata()
        if a == 255
    }
    if len(opaque_colors) > colors:
        raise ValueError(f"palette has {len(opaque_colors)} colors; maximum is {colors}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--frames", type=int, default=4)
    parser.add_argument("--frame-width", type=int, default=64)
    parser.add_argument("--frame-height", type=int, default=96)
    parser.add_argument("--key", type=parse_color, default=parse_color("ff00ff"))
    parser.add_argument("--colors", type=int, default=32)
    args = parser.parse_args()

    source = Image.open(args.input).convert("RGBA")
    if source.width % args.frames != 0:
        raise ValueError("source width must divide evenly into frame cells")
    source_width = source.width // args.frames
    output = Image.new("RGBA", (args.frames * args.frame_width, args.frame_height), (0, 0, 0, 0))
    for index in range(args.frames):
        cell = source.crop((index * source_width, 0, (index + 1) * source_width, source.height))
        frame = fit_frame(remove_key(cell, args.key), args.frame_width, args.frame_height)
        output.alpha_composite(frame, (index * args.frame_width, 0))

    alpha = output.getchannel("A")
    quantized_rgb = output.convert("RGB").quantize(
        colors=args.colors,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")
    output = quantized_rgb.convert("RGBA")
    output.putalpha(alpha)
    validate(output, args.frames, args.frame_width, args.frame_height, args.colors)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output)
    print("PIXEL_SHEET_VALID")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Exercise failure handling**

Run the finalizer against the knight reference GIF, which is not a keyed four-cell sheet:

```powershell
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .agents\skills\pixel-game-assets\scripts\finalize_pixel_sheet.py --input .agents\skills\pixel-game-assets\assets\knight-style-reference.gif --output $env:TEMP\invalid-sheet.png
```

Expected: nonzero exit with a clear empty-cell or key-background validation error.

- [ ] **Step 3: Re-run skill validation**

```powershell
powershell -ExecutionPolicy Bypass -File tests\validate_pixel_game_assets_skill.ps1
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'C:\Users\cynth\.codex\skills\.system\skill-creator\scripts\quick_validate.py' .agents\skills\pixel-game-assets
```

Expected: both pass.

- [ ] **Step 4: Commit the finalizer**

```powershell
git add .agents/skills/pixel-game-assets/scripts/finalize_pixel_sheet.py
git commit -m "feat: add pixel sheet finalizer"
```

### Task 4: Generate And Finalize The Warden Sample

**Files:**
- Create: `assets/characters/warden-pixel-sample-source.png`
- Create: `assets/characters/warden-pixel-sample.png`

- [ ] **Step 1: Generate the keyed source with the built-in image tool**

Use `.agents/skills/pixel-game-assets/assets/knight-style-reference.gif` as a style reference and this prompt:

```text
Use case: stylized-concept
Asset type: 2D pixel-art character animation sheet for a Godot fantasy idle RPG
Primary request: Create one Warden in exactly four poses: idle, walking, sword attack, taking a hit.
Style: authentic hand-authored pixel art matching the supplied armored knight reference; compact heroic proportions; chunky dark outline; clustered highlights; limited palette; hard square pixels; no antialiasing.
Character: navy cloak, steel chest guard, dark hair or helmet shadow, straight sword, worn leather, restrained warm-gold fittings.
Composition: one horizontal row of four equal cells in idle, walk, attack, hit order; identical identity, costume, scale, baseline, camera, and light direction; each figure fully visible and centered.
Background: perfectly flat uniform #ff00ff chroma key with no floor, shadows, gradients, texture, reflections, or color variation.
Constraints: no text, labels, borders, UI, scenery, extra characters, watermark, smooth rendering, painterly brushwork, or magenta on the subject.
```

Copy the selected generated image to `assets/characters/warden-pixel-sample-source.png` without deleting the generated original.

- [ ] **Step 2: Produce the exact production sheet**

```powershell
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .agents\skills\pixel-game-assets\scripts\finalize_pixel_sheet.py --input assets\characters\warden-pixel-sample-source.png --output assets\characters\warden-pixel-sample.png --frames 4 --frame-width 64 --frame-height 96 --key ff00ff --colors 32
```

Expected: `PIXEL_SHEET_VALID`, with output dimensions `256x96`.

- [ ] **Step 3: Inspect the source and final PNG**

Use `view_image` at original detail. Verify pose order, readable silhouette, consistent Warden identity, transparent background, stable baseline, crisp pixels, and no cropped sword or effects. If one invariant fails, revise only that issue in one new generation and rerun the finalizer.

- [ ] **Step 4: Run all validation**

```powershell
powershell -ExecutionPolicy Bypass -File tests\validate_pixel_game_assets_skill.ps1
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'C:\Users\cynth\.codex\skills\.system\skill-creator\scripts\quick_validate.py' .agents\skills\pixel-game-assets
& 'C:\Users\cynth\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .agents\skills\pixel-game-assets\scripts\finalize_pixel_sheet.py --input assets\characters\warden-pixel-sample-source.png --output assets\characters\warden-pixel-sample.png --frames 4 --frame-width 64 --frame-height 96 --key ff00ff --colors 32
```

Expected: skill test pass, skill validation pass, and `PIXEL_SHEET_VALID`.

- [ ] **Step 5: Commit the sample**

```powershell
git add assets/characters/warden-pixel-sample-source.png assets/characters/warden-pixel-sample.png
git commit -m "art: add pixel Warden sample"
```

### Task 5: Final Project Check

**Files:**
- Verify: `.agents/skills/pixel-game-assets/`
- Verify: `assets/characters/warden-pixel-sample.png`
- Verify: `project.godot`

- [ ] **Step 1: Confirm the live asset was not replaced**

Run:

```powershell
git diff -- assets/characters/warden-sprite-sheet.png project.godot Main.gd
```

Expected: no new changes caused by this plan.

- [ ] **Step 2: Run Godot import and boot verification**

```powershell
& 'D:\Program Files (x86)\godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'D:\Program Files (x86)\godot\Projects\Demo1\new-game-project' --quit-after 2
```

Expected: clean boot with no PNG import or script errors.

- [ ] **Step 3: Report both final paths and show the sample inline**

Report `.agents/skills/pixel-game-assets/SKILL.md` and `assets/characters/warden-pixel-sample.png`, state that the built-in image tool was used, include the final generation prompt, and render the final sample in the response.
