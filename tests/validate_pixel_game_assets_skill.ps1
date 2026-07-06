$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

$requiredPaths = @(
    '.agents\skills\pixel-game-assets\SKILL.md'
    '.agents\skills\pixel-game-assets\scripts\finalize_pixel_sheet.py'
    '.agents\skills\pixel-game-assets\assets\knight-style-reference.gif'
)

foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Missing required pixel game assets skill path: $relativePath"
    }
}

$skillPath = Join-Path $repoRoot '.agents\skills\pixel-game-assets\SKILL.md'
$skillContent = Get-Content -Raw -LiteralPath $skillPath
$requiredContracts = @(
    'Use when generating or editing any'
    '64 by 96'
    'nearest-neighbor'
    'no antialiasing'
    'transparent'
    'characters'
    'enemies'
    'buildings'
    'cards'
    'resources'
)

foreach ($contract in $requiredContracts) {
    if (-not $skillContent.Contains($contract)) {
        throw "SKILL.md is missing required literal contract: $contract"
    }
}

Write-Output 'PIXEL_GAME_ASSETS_SKILL_TEST_PASS'
