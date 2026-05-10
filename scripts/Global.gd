extends Node

const ARABIC_SIZE_BONUS: int = 4

var current_save_slot: int = -1
var show_slots_full_message: bool = false
var language: String = "en"
var current_locale: String = "en"
var previous_scene: String = ""
var player_name: String = ""
var arabic_font: FontFile = null
# english_font stays null: Godot's built-in default font is used for English everywhere
var english_font: FontFile = null
var quest_index: int = 1
var seal_count: int = 0
var player_character: String = ""
var completed_quests := {
	"quest1": false,
	"quest2": false,
	"quest3": false,
	"quest4": false,
	"quest5": false,
	"quest6": false,
}
var next_scene: String = ""

var tutorial_done: bool = false
var hint_shown_for_quest: int = 0

# 0 = no quiz pending. Set to quest number (1-6) when gameplay finishes.
# Stays set until the player PASSES the quiz
var pending_quiz_for_quest: int = 0


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var test_locale := TranslationServer.get_locale()
	if test_locale == "ar":
		set_language("ar")
	else:
		set_language("en")


func _process(_delta: float) -> void:
	# Keep the game windowed 
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func finish_quest_gameplay(n: int) -> void:
	var key := "quest%d" % n
	# Guard: don't double-process if gameplay was already finished
	if completed_quests.has(key) and completed_quests[key]:
		return
	if completed_quests.has(key):
		completed_quests[key] = true
	# Flag the quiz; quest_index stays unchanged until quiz is passed
	pending_quiz_for_quest = n



func award_seal(n: int) -> void:
	seal_count = clamp(seal_count + 1, 0, 6)
	if quest_index == n:
		quest_index = clamp(quest_index + 1, 1, 7)
	pending_quiz_for_quest = 0

func complete_quest(n: int) -> void:
	finish_quest_gameplay(n)


func set_language(locale: String) -> void:
	language = locale
	current_locale = locale
	TranslationServer.set_locale(locale)
	if locale == "ar":
		arabic_font = load("res://assets/fonts/NotoSansArabic-Regular.ttf")
	else:
		arabic_font = null
		_apply_arabic_font(get_tree().root, true)


func _apply_arabic_font(node: Node, remove: bool = false) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		if remove:
			node.remove_theme_font_override("font")
			node.remove_theme_font_size_override("font_size")
			if node is RichTextLabel:
				node.remove_theme_font_size_override("normal_font_size")
			if node is Label:
				node.remove_theme_constant_override("line_spacing")
				node.set("layout_direction", Control.LAYOUT_DIRECTION_LTR)
				node.set("text_direction", Control.TEXT_DIRECTION_LTR)
			elif node is Button:
				node.set("layout_direction", Control.LAYOUT_DIRECTION_LTR)
				node.set("text_direction", Control.TEXT_DIRECTION_LTR)
		else:
			if arabic_font != null:
				node.add_theme_font_override("font", arabic_font)
			if node is RichTextLabel:
				node.add_theme_font_size_override("normal_font_size", node.get_theme_font_size("normal_font_size") + ARABIC_SIZE_BONUS)
			else:
				node.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size") + ARABIC_SIZE_BONUS)
			if node is Label:
				node.add_theme_constant_override("line_spacing", -10)
				node.set("layout_direction", Control.LAYOUT_DIRECTION_RTL)
				node.set("text_direction", Control.TEXT_DIRECTION_RTL)
			elif node is Button:
				node.set("layout_direction", Control.LAYOUT_DIRECTION_RTL)
				node.set("text_direction", Control.TEXT_DIRECTION_RTL)
	for child in node.get_children():
		_apply_arabic_font(child, remove)


func fix_control_layout(node: Node) -> void:
	if node is Control:
		(node as Control).layout_direction = Control.LAYOUT_DIRECTION_LTR
	for child in node.get_children():
		fix_control_layout(child)
