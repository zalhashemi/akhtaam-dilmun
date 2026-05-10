extends Control

@onready var lbl_title   : Label         = $CenterContainer/VBoxContainer/LblTitle
@onready var btn_menu    : TextureButton = $CenterContainer/VBoxContainer/HBoxContainer/BtnMainMenu
@onready var btn_quit    : TextureButton = $CenterContainer/VBoxContainer/HBoxContainer/BtnQuit
@onready var lbl_menu    : Label         = $CenterContainer/VBoxContainer/HBoxContainer/BtnMainMenu/Label
@onready var lbl_quit    : Label         = $CenterContainer/VBoxContainer/HBoxContainer/BtnQuit/Label

func _ready() -> void:
	var is_ar := Global.current_locale == "ar"

	# Title
	lbl_title.text = "النهاية" if is_ar else "THE END"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 64)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))
	lbl_title.add_theme_constant_override("outline_size", 4)
	lbl_title.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 1.0))

	# Button labels
	if is_ar:
		lbl_menu.text = "القائمة الرئيسية"
		lbl_quit.text = "خروج"
	else:
		lbl_menu.text = "Back to Main Menu"
		lbl_quit.text = "Quit"

	for lbl in [lbl_menu, lbl_quit]:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)

	# Apply Arabic font if needed
	if is_ar and Global.arabic_font != null:
		for lbl in [lbl_title, lbl_menu, lbl_quit]:
			lbl.add_theme_font_override("font", Global.arabic_font)
			lbl.text_direction   = Control.TEXT_DIRECTION_RTL
			lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL
		lbl_title.add_theme_font_size_override("font_size", 64 + Global.ARABIC_SIZE_BONUS)
		for lbl in [lbl_menu, lbl_quit]:
			lbl.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)

	btn_menu.pressed.connect(_on_main_menu)
	btn_quit.pressed.connect(_on_quit)


func _on_main_menu() -> void:
	# Reset game state fully
	Global.tutorial_done        = false
	Global.hint_shown_for_quest = 0
	Global.quest_index          = 1
	Global.seal_count           = 0
	Global.pending_quiz_for_quest = 0
	Global.player_name          = ""
	Global.player_character     = ""
	Global.current_save_slot    = -1
	Global.completed_quests = {
		"quest1": false, "quest2": false, "quest3": false,
		"quest4": false, "quest5": false, "quest6": false,
	}
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_quit() -> void:
	get_tree().quit()
