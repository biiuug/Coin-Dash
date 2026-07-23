class_name SaveGameRules
extends RefCounted

const SAVE_VERSION := 4
const DURABLE_STATE_KEYS := [
	"materials",
	"inventory",
	"buildings",
	"unlocked_talents",
	"unlocked_achievements",
	"owned_relics",
	"selected_tab",
	"selected_hero",
	"selected_item",
	"equipment_filter",
	"auto_salvage_junk",
	"selected_building",
	"selected_talent",
	"stage_index",
	"best_stage",
	"battle_paused",
	"speed_index",
	"item_roll_counter",
]
const TRANSIENT_HERO_KEYS := ["hp", "max_hp", "attack_timer", "skill_timer"]


func build_snapshot(state: Dictionary, saved_at: float) -> Dictionary:
	var snapshot: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at": saved_at,
	}
	for key in DURABLE_STATE_KEYS:
		if state.has(key):
			snapshot[key] = state[key].duplicate(true) if state[key] is Array or state[key] is Dictionary else state[key]
	snapshot["heroes"] = _durable_heroes(state.get("heroes", []))
	return snapshot


func _durable_heroes(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var hero: Dictionary = (entry as Dictionary).duplicate(true)
		for key in TRANSIENT_HERO_KEYS:
			hero.erase(key)
		result.append(hero)
	return result
