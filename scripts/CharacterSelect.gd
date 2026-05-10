extends CanvasLayer

@onready var bg           : TextureRect    = $BG
@onready var lbl_title    : Label          = $Control/VBoxContainer/LblTitle
@onready var card_faisal  : PanelContainer = $Control/VBoxContainer/HBoxContainer/CardFaisal
@onready var card_dina    : PanelContainer = $Control/VBoxContainer/HBoxContainer/CardDina
@onready var btn_next     : TextureButton  = $Control/VBoxContainer/BtnNext
@onready var lbl_next     : Label          = $Control/VBoxContainer/BtnNext/Label

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

var selected_character: String = ""

func _ready() -> void:
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_update_labels()
	_apply_fonts()
	_apply_card_style(card_faisal, false)
	_apply_card_style(card_dina, false)

	card_faisal.gui_input.connect(_on_faisal_clicked)
	card_dina.gui_input.connect(_on_dina_clicked)
	btn_next.pressed.connect(_on_next_pressed)
	_add_back_button("res://scenes/NameEntry.tscn")


func _add_back_button(target_scene: String) -> void:
	var btn := Button.new()
	btn.text = "\u2190"
	btn.flat = true
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.add_theme_color_override("font_color", Color.RED)
	btn.add_theme_font_size_override("font_size", 52)
	btn.custom_minimum_size = Vector2(80, 64)
	btn.position = Vector2(16, 12)
	btn.pressed.connect(func(): get_tree().change_scene_to_file(target_scene))
	add_child(btn)

func _update_labels() -> void:
	var is_ar: bool = Global.language == "ar"
	if is_ar:
		lbl_title.text   = "اختر شخصيتك"
		lbl_next.text    = "التالي"
		for lbl in [lbl_title, lbl_next]:
			lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		lbl_title.text   = "Choose Your Character"
		lbl_next.text    = "Next"
		for lbl in [lbl_title, lbl_next]:
			lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Title outline
	lbl_title.add_theme_constant_override("outline_size", 6)
	lbl_title.add_theme_color_override("font_outline_color", Color("#3b1f0e"))
	lbl_title.add_theme_font_size_override("font_size", 32)

func _apply_fonts() -> void:
	if Global.language == "ar" and Global.arabic_font != null:
		for node in [lbl_title, lbl_next]:
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		for node in [lbl_title, lbl_next]:
			node.remove_theme_font_override("font")

func _apply_card_style(card: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE_SELECTED["bg_color"] if selected else STYLE_NORMAL["bg_color"]
	style.border_color = STYLE_SELECTED["border_color"] if selected else STYLE_NORMAL["border_color"]
	var bw: int = STYLE_SELECTED["border_width"] if selected else STYLE_NORMAL["border_width"]
	style.border_width_left   = bw
	style.border_width_right  = bw
	style.border_width_top    = bw
	style.border_width_bottom = bw
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", style)

func _on_faisal_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_character = "faisal"
		_apply_card_style(card_faisal, true)
		_apply_card_style(card_dina, false)

func _on_dina_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_character = "dina"
		_apply_card_style(card_dina, true)
		_apply_card_style(card_faisal, false)

func _on_next_pressed() -> void:
	if selected_character == "":
		return
	Global.player_character = selected_character
	Global.next_scene = "res://scenes/IntroVideo.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
