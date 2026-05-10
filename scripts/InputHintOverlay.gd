extends CanvasLayer

var _input_type: String = "mouse"

func setup(type: String) -> void:
	_input_type = type


func _ready() -> void:
	layer = 6
	_build()


func _build() -> void:
	var is_ar := Global.current_locale == "ar"

	var root := Control.new()
	root.anchor_left      = 0.0
	root.anchor_right     = 0.0
	root.anchor_top       = 1.0
	root.anchor_bottom    = 1.0
	root.offset_left      = 28.0
	root.offset_right     = 28.0
	root.offset_top       = -34.0
	root.offset_bottom    = -34.0
	root.grow_horizontal  = Control.GROW_DIRECTION_END
	root.grow_vertical    = Control.GROW_DIRECTION_BEGIN
	root.layout_mode      = 1
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR   # never flip with RTL locale
	root.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var bg := PanelContainer.new()
	bg.anchor_left    = 0.0
	bg.anchor_top     = 1.0
	bg.anchor_right   = 0.0
	bg.anchor_bottom  = 1.0
	bg.grow_horizontal = Control.GROW_DIRECTION_END
	bg.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	bg.layout_mode     = 1
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	bg.mouse_filter    = Control.MOUSE_FILTER_IGNORE

	var sty := StyleBoxFlat.new()
	sty.bg_color              = Color(0.05, 0.03, 0.01, 0.78)
	sty.border_color          = Color(0.65, 0.45, 0.18, 1.0)
	sty.border_width_left     = 2
	sty.border_width_right    = 2
	sty.border_width_top      = 2
	sty.border_width_bottom   = 2
	sty.corner_radius_top_left     = 10
	sty.corner_radius_top_right    = 10
	sty.corner_radius_bottom_left  = 10
	sty.corner_radius_bottom_right = 10
	bg.add_theme_stylebox_override("panel", sty)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.layout_direction = Control.LAYOUT_DIRECTION_LTR
	margin.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	bg.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment        = BoxContainer.ALIGNMENT_CENTER
	vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	if _input_type == "mouse":
		vbox.add_child(_build_mouse_icon())
	else:
		vbox.add_child(_build_arrow_keys_icon())

	var lbl := Label.new()
	lbl.text = ("الفأرة" if _input_type == "mouse" else "مفاتيح الأسهم") if is_ar \
			else ("Mouse"   if _input_type == "mouse" else "Arrow Keys")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.layout_direction     = Control.LAYOUT_DIRECTION_LTR   # no RTL flip
	lbl.text_direction       = Control.TEXT_DIRECTION_AUTO    # let engine detect script
	lbl.add_theme_font_size_override("font_size", 13)         # same size for all languages
	lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 0.65, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)


func _build_mouse_icon() -> Control:
	const W  := 28.0   # mouse body width
	const H  := 44.0   # mouse body height
	const R  := 14.0   # corner radius (fully rounded top)
	const SW := 6.0    # scroll wheel width
	const SH := 12.0   # scroll wheel height
	const SR := 3.0    # scroll wheel corner radius

	var nudge := MarginContainer.new()
	nudge.layout_direction      = Control.LAYOUT_DIRECTION_LTR
	nudge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nudge.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	if Global.current_locale == "ar":
		nudge.add_theme_constant_override("margin_left", 30)

	var c := Control.new()
	c.custom_minimum_size = Vector2(W, H)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.layout_direction      = Control.LAYOUT_DIRECTION_LTR
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var body := _make_rounded_rect(
		Vector2(0, 0), Vector2(W, H),
		R, R, 6.0, 6.0,
		Color(0.85, 0.85, 0.85, 1.0)
	)
	c.add_child(body)

	var divider := ColorRect.new()
	divider.color           = Color(0.4, 0.4, 0.4, 1.0)
	divider.position        = Vector2(W * 0.5 - 1.0, 0.0)
	divider.size            = Vector2(2.0, H * 0.45)
	divider.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	c.add_child(divider)

	var wheel := _make_rounded_rect(
		Vector2((W - SW) * 0.5, H * 0.14),
		Vector2(SW, SH),
		SR, SR, SR, SR,
		Color(0.5, 0.5, 0.5, 1.0)
	)
	c.add_child(wheel)

	var tail := _make_rounded_rect(
		Vector2(1.0, H * 0.5),
		Vector2(W - 2.0, H * 0.5 - 1.0),
		0.0, 0.0, 5.0, 5.0,
		Color(0.72, 0.72, 0.72, 1.0)
	)
	c.add_child(tail)

	nudge.add_child(c)
	return nudge


func _build_arrow_keys_icon() -> Control:
	const KEY := 22.0
	const GAP := 3.0

	
	var nudge := MarginContainer.new()
	nudge.layout_direction = Control.LAYOUT_DIRECTION_LTR
	nudge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nudge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Global.current_locale == "ar":
		nudge.add_theme_constant_override("margin_left", 20)

	var wrapper := VBoxContainer.new()
	wrapper.alignment        = BoxContainer.ALIGNMENT_CENTER
	wrapper.layout_direction = Control.LAYOUT_DIRECTION_LTR
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrapper.add_theme_constant_override("separation", int(GAP))
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_row := HBoxContainer.new()
	top_row.alignment        = BoxContainer.ALIGNMENT_CENTER
	top_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	top_row.add_theme_constant_override("separation", int(GAP))
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(_make_key(Vector2.ZERO, KEY, "↑"))
	wrapper.add_child(top_row)

	var bot_row := HBoxContainer.new()
	bot_row.alignment        = BoxContainer.ALIGNMENT_CENTER
	bot_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	bot_row.add_theme_constant_override("separation", int(GAP))
	bot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_row.add_child(_make_key(Vector2.ZERO, KEY, "←"))
	bot_row.add_child(_make_key(Vector2.ZERO, KEY, "↓"))
	bot_row.add_child(_make_key(Vector2.ZERO, KEY, "→"))
	wrapper.add_child(bot_row)

	nudge.add_child(wrapper)
	return nudge


func _make_key(pos: Vector2, size: float, arrow: String) -> Control:
	var c := Control.new()
	c.position   = pos
	c.custom_minimum_size = Vector2(size, size)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	c.layout_direction      = Control.LAYOUT_DIRECTION_LTR
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := _make_rounded_rect(
		Vector2.ZERO, Vector2(size, size),
		4.0, 4.0, 4.0, 4.0,
		Color(0.75, 0.75, 0.75, 1.0)
	)
	c.add_child(bg)

	var lbl := Label.new()
	lbl.text = arrow
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.anchor_left   = 0.0
	lbl.anchor_top    = 0.0
	lbl.anchor_right  = 1.0
	lbl.anchor_bottom = 1.0
	lbl.layout_mode   = 1
	lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)

	return c

func _make_rounded_rect(
	pos: Vector2, sz: Vector2,
	r_tl: float, r_tr: float, r_bl: float, r_br: float,
	color: Color
) -> Control:
	var p := Panel.new()
	p.position     = pos
	p.size         = sz
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var s := StyleBoxFlat.new()
	s.bg_color                      = color
	s.corner_radius_top_left        = int(r_tl)
	s.corner_radius_top_right       = int(r_tr)
	s.corner_radius_bottom_left     = int(r_bl)
	s.corner_radius_bottom_right    = int(r_br)
	s.border_width_left             = 0
	s.border_width_right            = 0
	s.border_width_top              = 0
	s.border_width_bottom           = 0
	p.add_theme_stylebox_override("panel", s)

	return p
