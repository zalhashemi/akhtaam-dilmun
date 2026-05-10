extends CanvasLayer

@export var in_quest: bool = false

@onready var options_button: TextureButton = $OptionsButton
@onready var overlay_panel: Control = $OverlayPanel
@onready var panel_bg: ColorRect = $OverlayPanel/PanelBackground
@onready var vbox: VBoxContainer = $OverlayPanel/VBox
@onready var title_label: Label = $OverlayPanel/VBox/TitleLabel
@onready var continue_btn: TextureButton = $OverlayPanel/VBox/ContinueButton
@onready var overworld_btn: TextureButton = $OverlayPanel/VBox/OverworldButton
@onready var settings_btn: TextureButton = $OverlayPanel/VBox/SettingsButton
@onready var main_menu_btn: TextureButton = $OverlayPanel/VBox/MainMenuButton
@onready var continue_lbl: Label = $OverlayPanel/VBox/ContinueButton/ContinueLabel
@onready var overworld_lbl: Label = $OverlayPanel/VBox/OverworldButton/OverworldLabel
@onready var settings_lbl: Label = $OverlayPanel/VBox/SettingsButton/SettingsLabel
@onready var main_menu_lbl: Label = $OverlayPanel/VBox/MainMenuButton/MainMenuLabel

var _origin_scene: String = ""


func _ready() -> void:
	overlay_panel.visible = false
	overworld_btn.visible = in_quest
	_apply_language()
	options_button.pressed.connect(_on_options_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	overworld_btn.pressed.connect(_on_overworld_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)


func _apply_language() -> void:
	var is_ar: bool = Global.language == "ar"
	title_label.text    = "الخيارات" if is_ar else "Options"
	continue_lbl.text   = "متابعة" if is_ar else "Continue"
	overworld_lbl.text  = "العودة للخريطة" if is_ar else "Back to Overworld"
	settings_lbl.text   = "الإعدادات" if is_ar else "Settings"
	main_menu_lbl.text  = "القائمة الرئيسية" if is_ar else "Main Menu"
	var dir := Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	for node in [title_label, continue_lbl, overworld_lbl, settings_lbl, main_menu_lbl]:
		node.layout_direction = dir
	options_button.layout_direction = Control.LAYOUT_DIRECTION_LTR

	if is_ar:
		options_button.anchor_left     = 0.0
		options_button.anchor_right    = 0.0
		options_button.offset_left     = 32.0
		options_button.offset_right    = 80.0
		options_button.grow_horizontal = Control.GROW_DIRECTION_END
	else:
		options_button.anchor_left     = 1.0
		options_button.anchor_right    = 1.0
		options_button.offset_left     = -80.0
		options_button.offset_right    = -32.0
		options_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _on_options_pressed() -> void:
	_origin_scene = get_tree().current_scene.scene_file_path
	overlay_panel.visible = true
	get_tree().paused = true


func _on_continue_pressed() -> void:
	overlay_panel.visible = false
	get_tree().paused = false


func _on_overworld_pressed() -> void:
	get_tree().paused = false
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_settings_pressed() -> void:
	Global.previous_scene = _origin_scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
