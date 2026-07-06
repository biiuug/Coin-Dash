# Pixel Game Assets Design

## Goal

Establish one reusable pixel-art direction for every generated image and animation in Idle Hero Camp, then produce a Warden character sample as the first reference asset.

## Art Direction

- Use crisp hand-authored pixel art with hard edges and no antialiasing.
- Match the supplied armored knight reference: compact heroic proportions, strong dark outline, readable metal highlights, and a controlled palette.
- Preserve silhouettes at gameplay scale. Fine detail must not become visual noise when shown around 68 by 84 screen pixels.
- Use transparent backgrounds for production assets. Chroma-key generation is acceptable only as an intermediate step.
- Do not use painterly rendering, smooth vector edges, gradients, photorealism, text, watermarks, or decorative backgrounds.

## Character Contract

- Logical frame size: 64 by 96 pixels.
- Sample sheet layout: four equal frames in one horizontal row.
- Frame order: idle, walk, attack, hit.
- Keep identity, proportions, palette, equipment, lighting direction, baseline, and scale consistent across frames.
- The Warden retains a navy cloak, steel chest guard, dark hair or helmet shadow, sword, worn leather, and restrained warm-metal accents.
- Scale previews only with nearest-neighbor interpolation.

## Project Skill

Create `.agents/skills/pixel-game-assets/SKILL.md` as the project-local authority for future image and animation generation. It will require agents to inspect existing references, follow the shared pixel contract, generate assets through the image tool, remove chroma-key backgrounds when needed, downsample with nearest-neighbor filtering, validate frame dimensions and transparency, and save final assets under `assets/`.

The supplied knight GIF will be retained inside the skill as its visual style reference so future generations do not depend on the original desktop path.

## Warden Sample Output

Generate a new Warden sprite sheet without overwriting the current production sheet. Save the transparent source as `assets/characters/warden-pixel-sample.png`. The sample is an art-direction candidate only; replacing the live character requires separate approval.

## Validation

- PNG dimensions are exactly 256 by 96 pixels.
- The image has an alpha channel and transparent corners.
- Each 64 by 96 frame contains one centered, fully visible Warden pose.
- Pixel edges remain crisp at 1x and integer preview scales.
- No reference-background color, labels, borders, or unrelated objects remain.
- The project-local skill passes its bundled skill validator.
