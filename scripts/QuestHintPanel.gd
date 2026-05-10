extends CanvasLayer
class_name QuestHintPanel
signal panel_done

const HINT_DELAY_SEC  := 8.0
const ARROW_DELAY_SEC := 30.0

const QUEST_NAMES_EN := {
	1: "Water",  2: "Earth",    3: "Pearls",
	4: "Harvest", 5: "Unity",  6: "Memory"
}
const QUEST_NAMES_AR := {
	1: "الماء",  2: "الأرض",  3: "اللؤلؤ",
	4: "الحصاد", 5: "الوحدة", 6: "الذاكرة"
}
const ORDINALS_EN := {
	1: "first", 2: "second", 3: "third",
	4: "fourth", 5: "fifth", 6: "sixth"
}
const ORDINALS_AR := {
	1: "الأولى",  2: "الثانية", 3: "الثالثة",
	4: "الرابعة", 5: "الخامسة", 6: "السادسة"
}
const LOCATIONS_EN := {
	1: "the well",         2: "the pottery house", 3: "the port",
	4: "the crops",        5: "the market",         6: "the fort"
}
const LOCATIONS_AR := {
	1: "البئر",   2: "بيت الفخار", 3: "الميناء",
	4: "المحاصيل", 5: "السوق",     6: "الحصن"
}

var _quest_num      : int    = 1
var _counting       : bool   = false
var _hint_shown     : bool   = false
var _hint_timer     : float  = 0.0
var _arrow_shown    : bool   = false
var _arrow_timer    : float  = 0.0
var _finished       : bool   = false

var _player_node    : Node   = null
var _quest_world_pos: Vector2 = Vector2.ZERO

var _dialog_root    : Control = null
var _hint_lbl       : Label   = null

var _arrow_shaft    : Line2D  = null
var _arrow_left     : Line2D  = null
var _arrow_right    : Line2D  = null


func setup(quest_num: int, quest_world_pos: Vector2 = Vector2.ZERO, player_node: Node = null) -> void:
	_quest_num       = quest_num
	_quest_world_pos = quest_world_pos
	_player_node     = player_node


func _ready() -> void:
	layer = 7
	_build_dialog()
	_build_hint_label()
	_build_arrow()


func _build_dialog() -> void:
	var is_ar := Global.current_locale == "ar"

	_dialog_root = Control.new()
	_dialog_root.anchor_left   = 0.0
	_dialog_root.anchor_top    = 0.0
	_dialog_root.anchor_right  = 1.0
	_dialog_root.anchor_bottom = 1.0
	_dialog_root.layout_mode   = 1
	_dialog_root.mouse_filter  = Control.MOUSE_FILTER_STOP
	add_child(_dialog_root)

	var overlay := ColorRect.new()
	overlay.color          = Color(0.0, 0.0, 0.0, 0.55)
	overlay.anchor_left    = 0.0
	overlay.anchor_top     = 0.0
	overlay.anchor_right   = 1.0
	overlay.anchor_bottom  = 1.0
	overlay.layout_mode    = 1
	overlay.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_dialog_root.add_child(overlay)

	var panel := Panel.new()
	panel.anchor_left   = 0.15
	panel.anchor_right  = 0.85
	panel.anchor_top    = 0.28
	panel.anchor_bottom = 0.72
	panel.layout_mode   = 1

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.06, 0.03, 0.97)
	panel_style.border_color = Color(0.75, 0.50, 0.25, 1.0)
	panel_style.border_width_left   = 3
	panel_style.border_width_right  = 3
	panel_style.border_width_top    = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left     = 14
	panel_style.corner_radius_top_right    = 14
	panel_style.corner_radius_bottom_left  = 14
	panel_style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	_dialog_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.anchor_left   = 0.0
	margin.anchor_top    = 0.0
	margin.anchor_right  = 1.0
	margin.anchor_bottom = 1.0
	margin.layout_mode   = 1
	margin.add_theme_constant_override("margin_left",   40)
	margin.add_theme_constant_override("margin_right",  40)
	margin.add_theme_constant_override("margin_top",    36)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 28)
	margin.add_child(vbox)

	var ordinal    : String = ORDINALS_AR[_quest_num]    if is_ar else ORDINALS_EN[_quest_num]
	var quest_name : String = QUEST_NAMES_AR[_quest_num] if is_ar else QUEST_NAMES_EN[_quest_num]

	var lbl := Label.new()
	if is_ar:
		lbl.text = "ابحث في البيئة عن المهمة %s: %s!" % [ordinal, quest_name]
		lbl.text_direction   = Control.TEXT_DIRECTION_RTL
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL
		if Global.arabic_font != null:
			lbl.add_theme_font_override("font", Global.arabic_font)
			lbl.add_theme_font_size_override("font_size", 24 + Global.ARABIC_SIZE_BONUS)
	else:
		lbl.text = "Look around the environment for the %s quest: %s!" % [ordinal, quest_name]
		lbl.add_theme_font_size_override("font_size", 24)

	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75, 1.0))
	vbox.add_child(lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment          = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	var btn := Button.new()
	if is_ar:
		btn.text = "حسناً!"
		btn.text_direction = Control.TEXT_DIRECTION_RTL
		if Global.arabic_font != null:
			btn.add_theme_font_override("font", Global.arabic_font)
			btn.add_theme_font_size_override("font_size", 22 + Global.ARABIC_SIZE_BONUS)
	else:
		btn.text = "Got it!"
		btn.add_theme_font_size_override("font_size", 22)

	btn.custom_minimum_size = Vector2(180, 56)
	btn.pressed.connect(_on_got_it)
	btn_row.add_child(btn)

func _build_hint_label() -> void:
	var is_ar := Global.current_locale == "ar"
	var location : String = LOCATIONS_AR[_quest_num] if is_ar else LOCATIONS_EN[_quest_num]

	_hint_lbl = Label.new()
	if is_ar:
		_hint_lbl.text = "تلميح: المهمة التي تبحث عنها بالقرب من %s" % location
		_hint_lbl.text_direction   = Control.TEXT_DIRECTION_RTL
		_hint_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
		if Global.arabic_font != null:
			_hint_lbl.add_theme_font_override("font", Global.arabic_font)
			_hint_lbl.add_theme_font_size_override("font_size", 30 + Global.ARABIC_SIZE_BONUS)
	else:
		_hint_lbl.text = "Hint: The quest you are looking for is near %s" % location
		_hint_lbl.add_theme_font_size_override("font_size", 30)

	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
	_hint_lbl.add_theme_constant_override("outline_size", 2)
	_hint_lbl.add_theme_color_override("font_outline_color", Color.BLACK)

	_hint_lbl.anchor_left   = 0.1
	_hint_lbl.anchor_right  = 0.9
	_hint_lbl.anchor_top    = 0.5
	_hint_lbl.anchor_bottom = 0.5
	_hint_lbl.offset_top    = -40.0
	_hint_lbl.offset_bottom = 40.0
	_hint_lbl.layout_mode   = 1
	_hint_lbl.visible = false
	add_child(_hint_lbl)

func _build_arrow() -> void:
	_arrow_shaft = Line2D.new()
	_arrow_shaft.width         = 5.0
	_arrow_shaft.default_color = Color(1.0, 0.85, 0.2, 0.85)
	_arrow_shaft.z_index       = 10
	_arrow_shaft.visible       = false
	add_child(_arrow_shaft)

	_arrow_left = Line2D.new()
	_arrow_left.width         = 5.0
	_arrow_left.default_color = Color(1.0, 0.85, 0.2, 0.85)
	_arrow_left.z_index       = 10
	_arrow_left.visible       = false
	add_child(_arrow_left)

	_arrow_right = Line2D.new()
	_arrow_right.width         = 5.0
	_arrow_right.default_color = Color(1.0, 0.85, 0.2, 0.85)
	_arrow_right.z_index       = 10
	_arrow_right.visible       = false
	add_child(_arrow_right)


func _update_arrow() -> void:
	if _player_node == null or not is_instance_valid(_player_node):
		return
	if _quest_world_pos == Vector2.ZERO:
		return

	var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
	var player_world: Vector2 = _player_node.global_position
	var player_screen: Vector2 = canvas_xform * player_world
	var quest_screen:  Vector2 = canvas_xform * _quest_world_pos

	var dir: Vector2 = (quest_screen - player_screen).normalized()
	var dist: float  = player_screen.distance_to(quest_screen)
	var shaft_len: float = min(dist * 0.55, 180.0)
	var tip: Vector2 = player_screen + dir * shaft_len

	_arrow_shaft.clear_points()
	_arrow_shaft.add_point(player_screen)
	_arrow_shaft.add_point(tip)

	const WING_LEN   := 22.0
	const WING_ANGLE := 0.45  # radians (~26°)
	var back: Vector2 = tip - dir * WING_LEN
	var perp: Vector2 = dir.rotated(PI * 0.5)

	_arrow_left.clear_points()
	_arrow_left.add_point(tip)
	_arrow_left.add_point(back + perp * WING_LEN * tan(WING_ANGLE))

	_arrow_right.clear_points()
	_arrow_right.add_point(tip)
	_arrow_right.add_point(back - perp * WING_LEN * tan(WING_ANGLE))

func _on_got_it() -> void:
	_dialog_root.visible = false
	_counting            = true
	_hint_timer          = 0.0
	_arrow_timer         = 0.0

func _process(delta: float) -> void:
	if not _counting:
		return

	if not _hint_shown:
		_hint_timer += delta
		if _hint_timer >= HINT_DELAY_SEC:
			_hint_shown       = true
			_hint_lbl.visible = true

	if not _arrow_shown:
		_arrow_timer += delta
		if _arrow_timer >= ARROW_DELAY_SEC:
			_arrow_shown = true
			_arrow_shaft.visible = true
			_arrow_left.visible  = true
			_arrow_right.visible = true

	if _arrow_shown:
		_update_arrow()


## Called by overworld when the player walks within proximity of the active quest.
func on_quest_found() -> void:
	if _finished:
		return
	_finished         = true
	_counting         = false
	_hint_lbl.visible = false
	_arrow_shaft.visible = false
	_arrow_left.visible  = false
	_arrow_right.visible = false
	panel_done.emit()
	queue_free()
