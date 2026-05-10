extends CanvasLayer

@onready var bg           : TextureRect    = $BG
@onready var lbl_title    : Label          = $Control/PanelContainer/VBoxContainer/LblTitle
@onready var card_english : PanelContainer = $Control/PanelContainer/VBoxContainer/HBoxContainer/CardEnglish
@onready var card_arabic  : PanelContainer = $Control/PanelContainer/VBoxContainer/HBoxContainer/CardArabic
@onready var lbl_english  : Label          = $Control/PanelContainer/VBoxContainer/HBoxContainer/CardEnglish/LblEnglish
@onready var lbl_arabic   : Label          = $Control/PanelContainer/VBoxContainer/HBoxContainer/CardArabic/LblArabic
@onready var btn_save     : TextureButton  = $Control/PanelContainer/VBoxContainer/HBoxContainer2/BtnSave
@onready var btn_back     : TextureButton  = $Control/PanelContainer/VBoxContainer/HBoxContainer2/BtnBack
@onready var lbl_save     : Label          = $Control/PanelContainer/VBoxContainer/HBoxContainer2/BtnSave/Label
@onready var lbl_back     : Label          = $Control/PanelContainer/VBoxContainer/HBoxContainer2/BtnBack/Label

const STYLE_NORMAL := {
	"bg_color"     : Color("#3b1f0e"),
	"border_color" : Color("#C27049"),
	"border_width" : 3
}
const STYLE_SELECTED := {
	"bg_color"     : Color("#5a2e10"),
	"border_color" : Color("#F2B983"),
	"border_width" : 5
}

var selected_language: String = ""


func _ready() -> void:
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR

	selected_language = Global.language
	_apply_card_style(card_english, selected_language == "en")
	_apply_card_style(card_arabic, selected_language == "ar")

	_update_labels()
	_apply_fonts()

	card_english.gui_input.connect(_on_english_clicked)
	card_arabic.gui_input.connect(_on_arabic_clicked)
	btn_save.pressed.connect(_on_save)
	btn_back.pressed.connect(_on_back)


func _update_labels() -> void:
	var is_ar: bool = Global.language == "ar"
	lbl_title.text   = "اختيار اللغة" if is_ar else "Language Selection"
	lbl_english.text = "English"
	lbl_arabic.text  = "العربية"
	lbl_save.text    = "حفظ التغييرات" if is_ar else "Save Changes"
	lbl_back.text    = "رجوع" if is_ar else "Back"

	lbl_title.add_theme_constant_override("outline_size", 6)
	lbl_title.add_theme_color_override("font_outline_color", Color("#3b1f0e"))

	for lbl in [lbl_title, lbl_save, lbl_back]:
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	lbl_english.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_arabic.layout_direction = Control.LAYOUT_DIRECTION_RTL
	lbl_arabic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _apply_fonts() -> void:
	if Global.language == "ar":
		var arabic_font := SystemFont.new()
		arabic_font.font_names = ["Tahoma", "Arial", "Segoe UI"]
		for node in [lbl_title, lbl_english, lbl_arabic, lbl_save, lbl_back]:
			node.add_theme_font_override("font", arabic_font)
			node.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		for node in [lbl_title, lbl_english, lbl_arabic, lbl_save, lbl_back]:
			node.remove_theme_font_override("font")


func _apply_card_style(card: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color     = STYLE_SELECTED["bg_color"]     if selected else STYLE_NORMAL["bg_color"]
	style.border_color = STYLE_SELECTED["border_color"] if selected else STYLE_NORMAL["border_color"]
	var bw: int        = STYLE_SELECTED["border_width"]  if selected else STYLE_NORMAL["border_width"]
	style.border_width_left   = bw
	style.border_width_right  = bw
	style.border_width_top    = bw
	style.border_width_bottom = bw
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style)


func _on_english_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_language = "en"
		_apply_card_style(card_english, true)
		_apply_card_style(card_arabic, false)


func _on_arabic_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_language = "ar"
		_apply_card_style(card_arabic, true)
		_apply_card_style(card_english, false)


func _on_save() -> void:
	if selected_language == "":
		return
	Global.set_language(selected_language)
	_return_to_previous()


func _on_back() -> void:
	_return_to_previous()


func _return_to_previous() -> void:
	var target := Global.previous_scene if Global.previous_scene != "" else "res://scenes/MainMenu.tscn"
	if target == "res://overworld.tscn":
		Global.next_scene = target
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
	else:
		get_tree().change_scene_to_file(target)
