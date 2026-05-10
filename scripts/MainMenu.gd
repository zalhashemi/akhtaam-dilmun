extends CanvasLayer

@onready var btn_new_game  : TextureButton = $Control/GridContainer/BtnNewGame
@onready var btn_load_game : TextureButton = $Control/GridContainer/BtnLoadGame
@onready var btn_settings  : TextureButton = $Control/GridContainer/BtnSettings
@onready var btn_quit      : TextureButton = $Control/GridContainer/BtnQuit

@onready var lbl_new_game  : Label = $Control/GridContainer/BtnNewGame/Label
@onready var lbl_load_game : Label = $Control/GridContainer/BtnLoadGame/Label
@onready var lbl_settings  : Label = $Control/GridContainer/BtnSettings/Label
@onready var lbl_quit      : Label = $Control/GridContainer/BtnQuit/Label

@onready var bg            : TextureRect = $BG
@onready var grid          : GridContainer = $Control/GridContainer

const LABELS_EN := {
	"new_game"  : "New Game",
	"load_game" : "Load Game",
	"settings"  : "Settings",
	"quit"      : "Quit"
}

const LABELS_AR := {
	"new_game"  : "لعبة جديدة",
	"load_game" : "تحميل اللعبة",
	"settings"  : "الإعدادات",
	"quit"      : "خروج"
}

func _ready() -> void:
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	grid.layout_direction = Control.LAYOUT_DIRECTION_LTR

	_update_labels()
	_apply_fonts()

	btn_new_game.pressed.connect(_on_new_game)
	btn_load_game.pressed.connect(_on_load_game)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

func _update_labels() -> void:
	var is_ar: bool = Global.language == "ar"

	if is_ar:
		lbl_new_game.text  = LABELS_AR["new_game"]
		lbl_load_game.text = LABELS_AR["load_game"]
		lbl_settings.text  = LABELS_AR["settings"]
		lbl_quit.text      = LABELS_AR["quit"]
	else:
		lbl_new_game.text  = LABELS_EN["new_game"]
		lbl_load_game.text = LABELS_EN["load_game"]
		lbl_settings.text  = LABELS_EN["settings"]
		lbl_quit.text      = LABELS_EN["quit"]

	for lbl in [lbl_new_game, lbl_load_game, lbl_settings, lbl_quit]:
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_fonts() -> void:
	if Global.language == "ar" and Global.arabic_font != null:
		for lbl in [lbl_new_game, lbl_load_game, lbl_settings, lbl_quit]:
			lbl.add_theme_font_override("font", Global.arabic_font)
			lbl.add_theme_font_size_override("font_size", 22 + Global.ARABIC_SIZE_BONUS)
	else:
		for lbl in [lbl_new_game, lbl_load_game, lbl_settings, lbl_quit]:
			lbl.remove_theme_font_override("font")
			lbl.add_theme_font_size_override("font_size", 20)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/NameEntry.tscn")

func _on_load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/LoadGame.tscn")

func _on_settings() -> void:
	Global.previous_scene = "res://scenes/MainMenu.tscn"
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit() -> void:
	get_tree().quit()
