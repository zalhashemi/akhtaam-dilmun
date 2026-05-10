extends CanvasLayer
class_name OverworldTutorial

signal tutorial_finished

const MOVE_THRESHOLD := 60.0   # pixels of accumulated movement to advance
const TIMEOUT_SEC    := 7.0    # auto-advance after this many seconds

var _player: CharacterBody2D = null
var _current_step := 0
var _accumulated   := 0.0
var _time_in_step  := 0.0
var _last_pos      := Vector2.ZERO
var _done          := false

# UI
var _key_label         : Label     = null
var _instruction_label : Label     = null


func init(player: CharacterBody2D) -> void:
	_player = player


func _ready() -> void:
	layer = 8
	_build_ui()
	if _player != null:
		_last_pos = _player.global_position
	_show_step(0)


func _build_ui() -> void:
	var is_ar := Global.current_locale == "ar"

	var strip := ColorRect.new()
	strip.color = Color(0.0, 0.0, 0.0, 0.78)
	strip.anchor_left   = 0.0
	strip.anchor_right  = 1.0
	strip.anchor_top    = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top    = -150.0
	strip.offset_bottom = 0.0
	strip.layout_mode   = 1
	strip.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.anchor_left   = 0.0
	hbox.anchor_right  = 1.0
	hbox.anchor_top    = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_top    = -140.0
	hbox.offset_bottom = -10.0
	hbox.layout_mode   = 1
	hbox.add_theme_constant_override("separation", 28)
	hbox.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(hbox)

	var key_panel := Panel.new()
	key_panel.custom_minimum_size = Vector2(88, 88)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.18, 1.0)
	style.border_color = Color(0.85, 0.85, 0.85, 1.0)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color  = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size   = 6
	style.shadow_offset = Vector2(0, 5)
	key_panel.add_theme_stylebox_override("panel", style)
	hbox.add_child(key_panel)

	_key_label = Label.new()
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_key_label.add_theme_font_size_override("font_size", 38)
	_key_label.add_theme_color_override("font_color", Color.WHITE)
	_key_label.anchor_left   = 0.0
	_key_label.anchor_top    = 0.0
	_key_label.anchor_right  = 1.0
	_key_label.anchor_bottom = 1.0
	_key_label.layout_mode   = 1
	_key_label.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	key_panel.add_child(_key_label)

	_instruction_label = Label.new()
	_instruction_label.add_theme_font_size_override("font_size",
			22 + (Global.ARABIC_SIZE_BONUS if is_ar else 0))
	_instruction_label.add_theme_color_override("font_color", Color.WHITE)
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_ar:
		_instruction_label.text_direction  = Control.TEXT_DIRECTION_RTL
		_instruction_label.layout_direction = Control.LAYOUT_DIRECTION_RTL
		if Global.arabic_font != null:
			_instruction_label.add_theme_font_override("font", Global.arabic_font)
	hbox.add_child(_instruction_label)


func _show_step(step: int) -> void:
	var is_ar := Global.current_locale == "ar"
	match step:
		0:
			_key_label.text = "↑"
			_instruction_label.text = "اضغط ↑ للتحرك للأعلى" if is_ar else "Press ↑ to move up"
		1:
			_key_label.text = "↓"
			_instruction_label.text = "اضغط ↓ للتحرك للأسفل" if is_ar else "Press ↓ to move down"
		2:
			_key_label.text = "←"
			_instruction_label.text = "اضغط ← للتحرك لليسار" if is_ar else "Press ← to move left"
		3:
			_key_label.text = "→"
			_instruction_label.text = "اضغط → للتحرك لليمين" if is_ar else "Press → to move right"
	_accumulated    = 0.0
	_time_in_step   = 0.0
	if _player != null:
		_last_pos = _player.global_position


func _process(delta: float) -> void:
	if _done or _player == null or _current_step >= 4:
		return

	_time_in_step += delta

	var cur_pos := _player.global_position
	var diff    := cur_pos - _last_pos
	_last_pos    = cur_pos

	match _current_step:
		0:   # UP   — y decreases
			if diff.y < -0.5:
				_accumulated += absf(diff.y)
		1:   # DOWN — y increases
			if diff.y > 0.5:
				_accumulated += diff.y
		2:   # LEFT — x decreases
			if diff.x < -0.5:
				_accumulated += absf(diff.x)
		3:   # RIGHT — x increases
			if diff.x > 0.5:
				_accumulated += diff.x

	if _accumulated >= MOVE_THRESHOLD or _time_in_step >= TIMEOUT_SEC:
		_advance()


func _advance() -> void:
	_current_step += 1
	if _current_step >= 4:
		_finish()
	else:
		_show_step(_current_step)


func _finish() -> void:
	if _done:
		return
	_done = true
	queue_free()
	tutorial_finished.emit()
