extends CanvasLayer

## Reusable step-by-step onboarding overlay.
##
## Usage (in any quest _ready()):
##   var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
##   tut.setup([ { "en": "...", "ar": "...", "target": Vector2(0.5,0.3), "align": "bottom" }, ... ])
##   tut.tutorial_done.connect(_on_tutorial_done)
##   add_child(tut)
##
## "align" controls which side of the TARGET the panel appears on:
##   "top"    → panel above the target
##   "bottom" → panel below the target   (default)
##   "left"   → panel left of the target
##   "right"  → panel right of the target
##
## "target" is a Vector2 in NORMALISED viewport space (0..1, 0..1).

signal tutorial_done
signal step_changed(index: int)

var _steps   : Array  = []
var _current : int    = 0
var _busy    : bool   = false

var _overlay     : ColorRect     = null
var _panel       : PanelContainer = null
var _text_lbl    : Label          = null
var _counter_lbl : Label          = null
var _btn         : Button         = null
var _footer      : HBoxContainer  = null
var _arrow       : Polygon2D      = null
var _dot_outer   : Polygon2D      = null
var _dot_inner   : Polygon2D      = null
var _overlay_img  : Sprite2D       = null
var step_preview  : Control        = null   


# ── Public API ────────────────────────────────────────────────────────────────

func setup(steps: Array) -> void:
	_steps = steps

func _ready() -> void:
	layer        = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build()
	_show_step(0)



func _build() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_overlay = ColorRect.new()
	_overlay.color         = Color(0.0, 0.0, 0.0, 0.58)
	_overlay.anchor_right  = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.layout_mode   = 1
	_overlay.mouse_filter  = Control.MOUSE_FILTER_STOP
	_overlay.process_mode  = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	_arrow              = Polygon2D.new()
	_arrow.color        = Color(1.0, 0.85, 0.25, 0.90)
	_arrow.z_index      = 3
	_arrow.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_arrow)

	_dot_outer              = Polygon2D.new()
	_dot_outer.color        = Color(1.0, 0.85, 0.25, 0.35)
	_dot_outer.z_index      = 4
	_dot_outer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dot_outer)

	_dot_inner              = Polygon2D.new()
	_dot_inner.color        = Color(1.0, 0.85, 0.25, 0.90)
	_dot_inner.z_index      = 5
	_dot_inner.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dot_inner)

	_overlay_img              = Sprite2D.new()
	_overlay_img.z_index      = 7
	_overlay_img.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay_img.visible      = false
	add_child(_overlay_img)

	step_preview                     = Control.new()
	step_preview.anchor_right        = 1.0
	step_preview.anchor_bottom       = 1.0
	step_preview.layout_mode         = 1
	step_preview.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	step_preview.process_mode        = Node.PROCESS_MODE_ALWAYS
	add_child(step_preview)

	_panel                     = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(vs.x * 0.44, 0.0)
	_panel.z_index             = 6
	_panel.process_mode        = Node.PROCESS_MODE_ALWAYS

	var sty := StyleBoxFlat.new()
	sty.bg_color                     = Color(0.07, 0.04, 0.01, 0.97)
	sty.border_color                 = Color(0.75, 0.52, 0.22, 1.0)
	sty.set_border_width_all(3)
	sty.corner_radius_top_left       = 14
	sty.corner_radius_top_right      = 14
	sty.corner_radius_bottom_left    = 14
	sty.corner_radius_bottom_right   = 14
	_panel.add_theme_stylebox_override("panel", sty)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    22)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.process_mode     = Node.PROCESS_MODE_ALWAYS
	margin.layout_direction = Control.LAYOUT_DIRECTION_LTR   
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.process_mode          = Node.PROCESS_MODE_ALWAYS
	margin.add_child(vbox)

	var is_ar_build := Global.current_locale == "ar"
	_text_lbl = Label.new()
	_text_lbl.autowrap_mode          = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	_text_lbl.add_theme_font_size_override("font_size", 20)
	_text_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82, 1.0))
	_text_lbl.add_theme_constant_override("outline_size", 1)
	_text_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_text_lbl.process_mode            = Node.PROCESS_MODE_ALWAYS
	
	if is_ar_build:
		_text_lbl.text_direction       = Control.TEXT_DIRECTION_RTL
		_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_text_lbl.layout_direction     = Control.LAYOUT_DIRECTION_LTR
		if Global.arabic_font != null:
			_text_lbl.add_theme_font_override("font", Global.arabic_font)
			_text_lbl.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		_text_lbl.text_direction       = Control.TEXT_DIRECTION_LTR
		_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_text_lbl.layout_direction     = Control.LAYOUT_DIRECTION_LTR
	vbox.add_child(_text_lbl)

	_footer = HBoxContainer.new()
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.process_mode          = Node.PROCESS_MODE_ALWAYS
	_footer.layout_direction      = Control.LAYOUT_DIRECTION_RTL if is_ar_build else Control.LAYOUT_DIRECTION_LTR
	vbox.add_child(_footer)

	_counter_lbl = Label.new()
	_counter_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	_counter_lbl.add_theme_font_size_override("font_size", 14)
	_counter_lbl.add_theme_color_override("font_color", Color(0.62, 0.58, 0.48, 1.0))
	_counter_lbl.process_mode    = Node.PROCESS_MODE_ALWAYS
	_counter_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR  # numbers stay LTR
	_footer.add_child(_counter_lbl)

	_btn = Button.new()
	_btn.custom_minimum_size = Vector2(150, 46)
	_btn.add_theme_font_size_override("font_size", 20)
	_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR  # keep chevron orientation
	_btn.pressed.connect(_on_next)
	_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_footer.add_child(_btn)


func _show_step(index: int) -> void:
	if index >= _steps.size():
		_finish()
		return

	_busy    = true
	_current = index

	var step    : Dictionary = _steps[index]
	var is_ar   : bool       = Global.current_locale == "ar"
	var vs      : Vector2    = get_viewport().get_visible_rect().size
	var is_last : bool       = (index == _steps.size() - 1)
	
	_text_lbl.text = step.get("ar", "") if is_ar else step.get("en", "")

	if is_ar:
		_text_lbl.text_direction       = Control.TEXT_DIRECTION_RTL
		_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_text_lbl.layout_direction     = Control.LAYOUT_DIRECTION_LTR
		_text_lbl.add_theme_constant_override("line_spacing", -10)
		if Global.arabic_font != null:
			_text_lbl.add_theme_font_override("font", Global.arabic_font)
			_text_lbl.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		_text_lbl.text_direction       = Control.TEXT_DIRECTION_LTR
		_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_text_lbl.layout_direction     = Control.LAYOUT_DIRECTION_LTR
		_text_lbl.remove_theme_constant_override("line_spacing")
		_text_lbl.remove_theme_font_override("font")
		_text_lbl.add_theme_font_size_override("font_size", 20)

	if is_ar:
		var ts := TextServerManager.get_primary_interface()
		_counter_lbl.text = "%s / %s" % [
			ts.format_number("%d" % (index + 1)),
			ts.format_number("%d" % _steps.size())
		]
		_counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if Global.arabic_font != null:
			_counter_lbl.add_theme_font_override("font", Global.arabic_font)
			_counter_lbl.add_theme_font_size_override("font_size", 14 + Global.ARABIC_SIZE_BONUS)
	else:
		_counter_lbl.text              = "Step %d of %d" % [index + 1, _steps.size()]
		_counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_counter_lbl.remove_theme_font_override("font")
		_counter_lbl.add_theme_font_size_override("font_size", 14)

	if is_ar:
		_btn.text = "ابدأ!" if is_last else "التالي  ›"
		if Global.arabic_font != null:
			_btn.add_theme_font_override("font", Global.arabic_font)
			_btn.add_theme_font_size_override("font_size", 20 + Global.ARABIC_SIZE_BONUS)
	else:
		_btn.text = "Let's go!" if is_last else "Next  ›"
		_btn.remove_theme_font_override("font")
		_btn.add_theme_font_size_override("font_size", 20)

	await get_tree().process_frame

	var target_norm : Vector2
	if is_ar and step.has("target_ar"):
		target_norm = step.get("target_ar")
	else:
		target_norm = step.get("target", Vector2(0.5, 0.5))
	var target : Vector2 = target_norm * vs
	var align  : String
	if is_ar and step.has("align_ar"):
		align = step.get("align_ar")
	else:
		align  = step.get("align", "bottom")
	var ps          : Vector2 = _panel.size
	const GAP       := 62.0  

	var overlay_path : String = step.get("overlay_image", "")
	if overlay_path != "":
		var tex : Texture2D   = load(overlay_path)
		_overlay_img.texture  = tex
		const TARGET_H        := 90.0
		var th                := float(tex.get_height())
		_overlay_img.scale    = Vector2(TARGET_H / th, TARGET_H / th) if th > 0.0 else Vector2(0.25, 0.25)
		_overlay_img.position = target
		_overlay_img.visible  = true
		_dot_outer.visible    = false
		_dot_inner.visible    = false
	else:
		_overlay_img.visible = false
		_dot_outer.visible   = true
		_dot_inner.visible   = true

	var px := 0.0
	var py := 0.0

	match align:
		"top":
			px = clamp(target.x - ps.x * 0.5, 12.0, vs.x - ps.x - 12.0)
			py = clamp(target.y - ps.y - GAP,  12.0, vs.y - ps.y - 12.0)
		"bottom":
			px = clamp(target.x - ps.x * 0.5, 12.0, vs.x - ps.x - 12.0)
			py = clamp(target.y + GAP,          12.0, vs.y - ps.y - 12.0)
		"left":
			px = clamp(target.x - ps.x - GAP,  12.0, vs.x - ps.x - 12.0)
			py = clamp(target.y - ps.y * 0.5,  12.0, vs.y - ps.y - 12.0)
		"right":
			px = clamp(target.x + GAP,          12.0, vs.x - ps.x - 12.0)
			py = clamp(target.y - ps.y * 0.5,  12.0, vs.y - ps.y - 12.0)
		_:
			px = clamp(target.x - ps.x * 0.5, 12.0, vs.x - ps.x - 12.0)
			py = clamp(target.y + GAP,          12.0, vs.y - ps.y - 12.0)

	_panel.position = Vector2(px, py)

	var base : Vector2
	match align:
		"top":    base = Vector2(px + ps.x * 0.5, py + ps.y)
		"bottom": base = Vector2(px + ps.x * 0.5, py)
		"left":   base = Vector2(px + ps.x,        py + ps.y * 0.5)
		"right":  base = Vector2(px,               py + ps.y * 0.5)
		_:        base = Vector2(px + ps.x * 0.5, py)

	var dir  : Vector2 = (target - base).normalized()
	var perp : Vector2 = Vector2(-dir.y, dir.x)
	_arrow.polygon = PackedVector2Array([
		target,
		base + perp * 9.0,
		base - perp * 9.0
	])

	const OUTER_R := 20.0
	const INNER_R := 10.0
	var outer_pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	for i in range(28):
		var a := TAU * i / 28.0
		outer_pts.append(target + Vector2(cos(a), sin(a)) * OUTER_R)
		inner_pts.append(target + Vector2(cos(a), sin(a)) * INNER_R)
	_dot_outer.polygon = outer_pts
	_dot_inner.polygon = inner_pts

	step_changed.emit(index)
	_busy = false

func _on_next() -> void:
	if _busy:
		return
	_show_step(_current + 1)


func _finish() -> void:
	get_tree().paused = false
	tutorial_done.emit()
	queue_free()
