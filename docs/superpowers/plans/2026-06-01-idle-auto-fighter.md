# Idle Auto-Fighter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current card-combat prototype with a compact desktop idle auto-fighter with heroes, stages, loot, equipment, buildings, and talents.

**Architecture:** Move rules/static data into `IdleGameRules.gd`, and rewrite `Main.gd` as a compact UI/controller for auto battle and progression. Keep existing image assets as simple first-version art where useful.

**Tech Stack:** Godot 4.6 GDScript, programmatic `Control` UI, existing PNG sprite sheets.

---

### Task 1: Idle Rules Model

**Files:**
- Create: `IdleGameRules.gd`
- Keep: `CardGameRules.gd` unused for now until cleanup is requested.

- [ ] Add hero class, hero, stage, building, talent, equipment, and loot definitions.
- [ ] Add stat calculation helpers for class, level, rank, equipment, buildings, and talents.
- [ ] Add deterministic equipment generation from stage and rarity.
- [ ] Add affordability helpers for leveling, skills, class rank, buildings, talents, and gear upgrades.

### Task 2: Compact Idle Game UI

**Files:**
- Replace: `Main.gd`
- Modify: `project.godot`

- [ ] Set window to compact desktop scale.
- [ ] Remove card hand/deck/energy gameplay.
- [ ] Add auto battle lane with up to 5 heroes and enemies.
- [ ] Add tabs for Heroes, Equipment, Buildings, Talents, and Levels.
- [ ] Add buttons for push/farm, hero upgrades, equipment equip/upgrade/salvage, building upgrade/actions, and talent unlocks.

### Task 3: Progression Wiring

**Files:**
- Modify: `Main.gd`

- [ ] Tick auto combat in `_process`.
- [ ] Award resources, equipment, shards, and essence from waves/stages.
- [ ] Support level progression and stage pushing.
- [ ] Support equipping, upgrading, and salvaging equipment.
- [ ] Support class rank and skill upgrades.
- [ ] Support building levels and talent unlocks.

### Task 4: Docs And Verification

**Files:**
- Modify: `README.md`

- [ ] Update docs to describe the idle auto-fighter.
- [ ] Run Godot headless boot verification.
- [ ] Inspect for remaining card UI references in active code.
