extends CanvasLayer

@onready var lbl_title  : Label    = $Control/PanelContainer/VBoxContainer/LblTitle
@onready var lbl_error  : Label    = $Control/PanelContainer/VBoxContainer/LblError
@onready var name_input : LineEdit = $Control/PanelContainer/VBoxContainer/NameInput
@onready var btn_next   : TextureButton = $Control/PanelContainer/VBoxContainer/BtnNext
@onready var lbl_next   : Label    = $Control/PanelContainer/VBoxContainer/BtnNext/Label
@onready var bg         : TextureRect = $BG

const VALID_REGEX := "^[a-zA-Zأ-يءآأؤإئابتثجحخدذرزسشصضطظعغفقكلمنهوىةی\\s]+$"

func _ready() -> void:
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	lbl_error.visible = false
	_update_labels()
	_apply_fonts()
	btn_next.pressed.connect(_on_next_pressed)
	_add_back_button("res://scenes/MainMenu.tscn")


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
		lbl_title.text = "أدخل اسمك"
		lbl_next.text  = "التالي"
		name_input.placeholder_text = "اكتب اسمك هنا..."
		name_input.layout_direction = Control.LAYOUT_DIRECTION_RTL
		lbl_title.layout_direction  = Control.LAYOUT_DIRECTION_RTL
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		lbl_title.text = "Enter Your Name"
		lbl_next.text  = "Next"
		name_input.placeholder_text = "Type your name here..."
		name_input.layout_direction = Control.LAYOUT_DIRECTION_LTR
		lbl_title.layout_direction  = Control.LAYOUT_DIRECTION_LTR
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_fonts() -> void:
	if Global.language == "ar" and Global.arabic_font != null:
		for node in [lbl_title, lbl_error, name_input, lbl_next]:
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		for node in [lbl_title, lbl_error, name_input, lbl_next]:
			node.remove_theme_font_override("font")

func _on_next_pressed() -> void:
	var entered_name := name_input.text.strip_edges()

	if entered_name.length() == 0:
		_show_error("Please enter a name." if Global.language == "en" else "الرجاء إدخال اسم.")
		return

	var regex := RegEx.new()
	regex.compile(VALID_REGEX)
	if not regex.search(entered_name):
		_show_error("Name must contain letters only." if Global.language == "en" else "يجب أن يحتوي الاسم على أحرف فقط.")
		return

	# Block duplicate names across existing save slots
	if SaveManager.name_exists_in_any_slot(entered_name):
		_show_error("This name is already used." if Global.language == "en" else "هذا الاسم مستخدم بالفعل.")
		return

	# Check if all slots are full before proceeding
	if SaveManager.all_slots_full():
		Global.show_slots_full_message = true
		get_tree().change_scene_to_file("res://scenes/LoadGame.tscn")
		return

	Global.player_name = entered_name
	Global.current_save_slot = SaveManager.get_first_empty_slot()
	lbl_error.visible = false
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _show_error(msg: String) -> void:
	lbl_error.text = msg
	lbl_error.visible = true
