extends CanvasLayer

@onready var bg           : TextureRect    = $BG
@onready var lbl_title    : Label          = $Control/VBoxContainer/LblTitle
@onready var lbl_message  : Label          = $Control/VBoxContainer/LblMessage
@onready var slot1        : PanelContainer = $Control/VBoxContainer/Slot1
@onready var slot2        : PanelContainer = $Control/VBoxContainer/Slot2
@onready var slot3        : PanelContainer = $Control/VBoxContainer/Slot3
@onready var lbl_slot1    : Label          = $Control/VBoxContainer/Slot1/LblSlot1
@onready var lbl_slot2    : Label          = $Control/VBoxContainer/Slot2/LblSlot2
@onready var lbl_slot3    : Label          = $Control/VBoxContainer/Slot3/LblSlot3
@onready var hbox_buttons : HBoxContainer  = $Control/VBoxContainer/HBoxContainer
@onready var btn_continue : TextureButton  = $Control/VBoxContainer/HBoxContainer/BtnContinue
@onready var btn_delete   : TextureButton  = $Control/VBoxContainer/HBoxContainer/BtnDelete
@onready var btn_back     : TextureButton  = $Control/VBoxContainer/CenterContainer/BtnBack
@onready var lbl_back     : Label          = $Control/VBoxContainer/CenterContainer/BtnBack/Label
@onready var lbl_continue : Label          = $Control/VBoxContainer/HBoxContainer/BtnContinue/Label
@onready var lbl_delete   : Label          = $Control/VBoxContainer/HBoxContainer/BtnDelete/Label
@onready var confirm_delete  : PanelContainer = $Control/VBoxContainer/ConfirmDelete
@onready var lbl_confirm     : Label          = $Control/VBoxContainer/ConfirmDelete/VBoxContainer/LblConfirm
@onready var btn_confirm_yes : TextureButton  = $Control/VBoxContainer/ConfirmDelete/VBoxContainer/HBoxContainer/BtnConfirmYes
@onready var btn_confirm_no  : TextureButton  = $Control/VBoxContainer/ConfirmDelete/VBoxContainer/HBoxContainer/BtnConfirmNo
@onready var lbl_confirm_yes : Label          = $Control/VBoxContainer/ConfirmDelete/VBoxContainer/HBoxContainer/BtnConfirmYes/Label
@onready var lbl_confirm_no  : Label          = $Control/VBoxContainer/ConfirmDelete/VBoxContainer/HBoxContainer/BtnConfirmNo/Label

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

var selected_slot: int = -1
var slots: Array
var slot_labels: Array

func _ready() -> void:
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	slots = [slot1, slot2, slot3]
	slot_labels = [lbl_slot1, lbl_slot2, lbl_slot3]
	hbox_buttons.visible = false
	lbl_message.visible = false
	confirm_delete.visible = false

	_update_labels()
	_apply_fonts()
	_populate_slots()

	slot1.gui_input.connect(_on_slot_clicked.bind(1))
	slot2.gui_input.connect(_on_slot_clicked.bind(2))
	slot3.gui_input.connect(_on_slot_clicked.bind(3))

	btn_continue.pressed.connect(_on_continue)
	btn_delete.pressed.connect(_on_delete)
	btn_back.pressed.connect(_on_back)
	btn_confirm_yes.pressed.connect(_on_confirm_yes)
	btn_confirm_no.pressed.connect(_on_confirm_no)
	_add_back_arrow()

	if Global.show_slots_full_message:
		lbl_message.visible = true
		lbl_message.text = "Please delete a slot to start a new game." if Global.language == "en" else "يرجى حذف خانة للبدء بلعبة جديدة."
		Global.show_slots_full_message = false

func _populate_slots() -> void:
	for i in range(3):
		var slot_num := i + 1
		var preview := SaveManager.read_slot_preview(slot_num)
		_apply_slot_style(slots[i], false)
		if preview.is_empty():
			slot_labels[i].text = "Empty Slot" if Global.language == "en" else "خانة فارغة"
		else:
			slot_labels[i].text = "%s — %s" % [preview["player_name"], preview["last_played"]]

func _apply_slot_style(slot: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = STYLE_SELECTED["bg_color"] if selected else STYLE_NORMAL["bg_color"]
	style.border_color = STYLE_SELECTED["border_color"] if selected else STYLE_NORMAL["border_color"]
	var bw: int = STYLE_SELECTED["border_width"] if selected else STYLE_NORMAL["border_width"]
	style.border_width_left   = bw
	style.border_width_right  = bw
	style.border_width_top    = bw
	style.border_width_bottom = bw
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	slot.add_theme_stylebox_override("panel", style)

func _on_slot_clicked(event: InputEvent, slot_num: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var preview := SaveManager.read_slot_preview(slot_num)
		if preview.is_empty():
			return
		selected_slot = slot_num
		for i in range(3):
			_apply_slot_style(slots[i], i + 1 == selected_slot)
		hbox_buttons.visible = true
		confirm_delete.visible = false
		lbl_message.visible = false

func _on_continue() -> void:
	if selected_slot == -1:
		return
	var success := SaveManager.load_game(selected_slot)
	if success:
		Global.next_scene = "res://overworld.tscn"
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_delete() -> void:
	if selected_slot == -1:
		return
	confirm_delete.visible = true
	hbox_buttons.visible = false
	var is_ar: bool = Global.language == "ar"
	lbl_confirm.text = "هل أنت متأكد أنك تريد حذف هذه اللعبة؟" if is_ar else "Are you sure you want to delete this saved game?"
	lbl_confirm_yes.text = "نعم" if is_ar else "Yes"
	lbl_confirm_no.text  = "لا" if is_ar else "No"
	lbl_confirm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for lbl in [lbl_confirm, lbl_confirm_yes, lbl_confirm_no]:
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_confirm_yes() -> void:
	SaveManager.delete_save(selected_slot)
	selected_slot = -1
	confirm_delete.visible = false
	hbox_buttons.visible = false
	_populate_slots()

func _on_confirm_no() -> void:
	confirm_delete.visible = false
	hbox_buttons.visible = true

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _add_back_arrow() -> void:
	var btn := Button.new()
	btn.text = "\u2190"
	btn.flat = true
	btn.add_theme_color_override("font_color", Color.RED)
	btn.add_theme_font_size_override("font_size", 52)
	btn.custom_minimum_size = Vector2(80, 64)
	btn.position = Vector2(16, 12)
	btn.pressed.connect(_on_back)
	add_child(btn)

func _update_labels() -> void:
	var is_ar: bool = Global.language == "ar"
	lbl_title.text    = "تحميل اللعبة" if is_ar else "Load Game"
	lbl_continue.text = "متابعة" if is_ar else "Continue"
	lbl_delete.text   = "حذف" if is_ar else "Delete"
	lbl_back.text     = "رجوع" if is_ar else "Back"
	lbl_title.add_theme_constant_override("outline_size", 6)
	lbl_title.add_theme_color_override("font_outline_color", Color("#3b1f0e"))
	for lbl in [lbl_title, lbl_continue, lbl_delete, lbl_back]:
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_fonts() -> void:
	if Global.language == "ar" and Global.arabic_font != null:
		for node in [lbl_title, lbl_message, lbl_slot1, lbl_slot2, lbl_slot3,
					 lbl_continue, lbl_delete, lbl_back, lbl_confirm,
					 lbl_confirm_yes, lbl_confirm_no]:
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		for node in [lbl_title, lbl_message, lbl_slot1, lbl_slot2, lbl_slot3,
					 lbl_continue, lbl_delete, lbl_back, lbl_confirm,
					 lbl_confirm_yes, lbl_confirm_no]:
			node.remove_theme_font_override("font")
