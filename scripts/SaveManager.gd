extends Node

const SAVE_DIR := "user://"
const SLOT_COUNT := 3

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_%d.json" % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_first_empty_slot() -> int:
	for i in range(1, SLOT_COUNT + 1):
		if not slot_exists(i):
			return i
	return -1

func all_slots_full() -> bool:
	return get_first_empty_slot() == -1

func name_exists_in_any_slot(name: String, excluding_slot: int = -1) -> bool:
	for i in range(1, SLOT_COUNT + 1):
		if i == excluding_slot:
			continue
		var preview := read_slot_preview(i)
		if not preview.is_empty():
			if preview["player_name"].strip_edges().to_lower() == name.strip_edges().to_lower():
				return true
	return false

func save_game(slot: int) -> void:
	var data := {
		"slot"             : slot,
		"player_name"      : Global.player_name,
		"player_character" : Global.player_character,
		"quest_index"      : Global.quest_index,
		"seal_count"       : Global.seal_count,
		"completed_quests" : Global.completed_quests,
		"last_played"      : _get_date_string()
	}
	var file := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game(slot: int) -> bool:
	if not slot_exists(slot):
		return false
	var file := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file:
		return false
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null or not parsed is Dictionary:
		return false
	Global.player_name       = parsed.get("player_name", "")
	Global.player_character  = parsed.get("player_character", "faisal")
	Global.quest_index       = parsed.get("quest_index", 1)
	Global.seal_count        = parsed.get("seal_count", 0)
	Global.completed_quests  = parsed.get("completed_quests", {
		"quest1": false, "quest2": false, "quest3": false,
		"quest4": false, "quest5": false, "quest6": false
	})
	Global.current_save_slot = slot
	return true

func delete_save(slot: int) -> void:
	var path := get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_clear_global_if_active_slot(slot)

func _clear_global_if_active_slot(slot: int) -> void:
	if Global.current_save_slot == slot:
		Global.player_name       = ""
		Global.player_character  = "faisal"
		Global.quest_index       = 1
		Global.seal_count        = 0
		Global.completed_quests  = {
			"quest1": false, "quest2": false, "quest3": false,
			"quest4": false, "quest5": false, "quest6": false
		}
		Global.current_save_slot = -1

func read_slot_preview(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file:
		return {}
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null or not parsed is Dictionary:
		return {}
	return {
		"player_name"      : parsed.get("player_name", "?"),
		"player_character" : parsed.get("player_character", "faisal"),
		"quest_index"      : parsed.get("quest_index", 1),
		"seal_count"       : parsed.get("seal_count", 0),
		"last_played"      : parsed.get("last_played", "??/??/??")
	}

func _get_date_string() -> String:
	var d := Time.get_date_dict_from_system()
	return "%02d/%02d/%02d" % [d["day"], d["month"], d["year"] % 100]
