extends CanvasLayer

# Usage:
#   var overlay := load("res://scripts/InputHintOverlay.gd").new()
#   overlay.setup("mouse")        # or "arrow_keys"
#   add_child(overlay)

var _input_type: String = "mouse"

func setup(type: String) -> void:
	_input_type = type


func _ready() -> void:
	layer = 6
	_build()


func _build() -> void:
	var is_ar := Global.current_locale == "ar"

	# ── Outer container anchored to bottom-left ───────────────────────────────
	var root := Control.new()
	root.anchor_left   = 1.0
	root.anchor_top    = 1.0
	root.anchor_right  = 1.0
	root.anchor_bottom = 1.0
	root.offset_left   = -104.0
	root.offset_top    = -34.0   # 14px margin + 20px higher
	root.offset_right  = -104.0
	root.offset_bottom = -34.0
	root.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	root.layout_mode     = 1
	root.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Background pill ───────────────────────────────────────────────────────
	var bg := PanelContainer.new()
	bg.anchor_left   = 0.0
	bg.anchor_top    = 1.0
	bg.anchor_right  = 0.0
	bg.anchor_bottom = 1.0
	bg.grow_horizontal = Control.GROW_DIRECTION_END
	bg.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	bg.layout_mode     = 1
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
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# ── Icon area ─────────────────────────────────────────────────────────────
	if _input_type == "mouse":
		vbox.add_child(_build_mouse_icon())
	else:
		vbox.add_child(_build_arrow_keys_icon())

	# ── Label ─────────────────────────────────────────────────────────────────
	var lbl := Label.new()
	if _input_type == "mouse":
		lbl.text = "الفأرة" if is_ar else "Mouse"
	else:
		lbl.text = "مفاتيح الأسهم" if is_ar else "Arrow Keys"

	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 0.65, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_ar and Global.arabic_font != null:
		lbl.add_theme_font_override("font", Global.arabic_font)
		lbl.add_theme_font_size_override("font_size", 13 + Global.ARABIC_SIZE_BONUS)
		lbl.text_direction   = Control.TEXT_DIRECTION_RTL
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL

	vbox.add_child(lbl)


# ── Mouse icon ────────────────────────────────────────────────────────────────
func _build_mouse_icon() -> Control:
	const W  := 28.0   # mouse body width
	const H  := 44.0   # mouse body height
	const R  := 14.0   # corner radius (fully rounded top)
	const SW := 6.0    # scroll wheel width
	const SH := 12.0   # scroll wheel height
	const SR := 3.0    # scroll wheel corner radius

	var c := Control.new()
	c.custom_minimum_size = Vector2(W, H)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Body
	var body := _make_rounded_rect(
		Vector2(0, 0), Vector2(W, H),
		R, R, 6.0, 6.0,
		Color(0.85, 0.85, 0.85, 1.0)
	)
	c.add_child(body)

	# Button divider line (vertical, top half)
	var divider := ColorRect.new()
	divider.color           = Color(0.4, 0.4, 0.4, 1.0)
	divider.position        = Vector2(W * 0.5 - 1.0, 0.0)
	divider.size            = Vector2(2.0, H * 0.45)
	divider.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	c.add_child(divider)

	# Scroll wheel
	var wheel := _make_rounded_rect(
		Vector2((W - SW) * 0.5, H * 0.14),
		Vector2(SW, SH),
		SR, SR, SR, SR,
		Color(0.5, 0.5, 0.5, 1.0)
	)
	c.add_child(wheel)

	# Bottom tail (darker rounded rect for lower body)
	var tail := _make_rounded_rect(
		Vector2(1.0, H * 0.5),
		Vector2(W - 2.0, H * 0.5 - 1.0),
		0.0, 0.0, 5.0, 5.0,
		Color(0.72, 0.72, 0.72, 1.0)
	)
	c.add_child(tail)

	return c


# ── Arrow keys icon ───────────────────────────────────────────────────────────
func _build_arrow_keys_icon() -> Control:
	const KEY  := 22.0   # key size (square)
	const GAP  := 3.0    # gap between keys
	const STEP := KEY + GAP

	# Total size: 3 keys wide, 2 keys tall (top row: just ↑ centred; bottom: ← ↓ →)
	var total_w := STEP * 3.0 - GAP
	var total_h := STEP * 2.0 - GAP

	var c := Control.new()
	c.custom_minimum_size = Vector2(total_w, total_h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Positions: up = top-center; left/down/right = bottom row
	var positions := {
		"↑": Vector2(STEP, 0),
		"←": Vector2(0,    STEP),
		"↓": Vector2(STEP, STEP),
		"→": Vector2(STEP * 2.0, STEP),
	}

	for arrow in positions:
		c.add_child(_make_key(positions[arrow], KEY, arrow))

	return c


func _make_key(pos: Vector2, size: float, arrow: String) -> Control:
	var c := Control.new()
	c.position   = pos
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Key background
	var bg := _make_rounded_rect(
		Vector2.ZERO, Vector2(size, size),
		4.0, 4.0, 4.0, 4.0,
		Color(0.75, 0.75, 0.75, 1.0)
	)
	c.add_child(bg)

	# Arrow label
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


# ── Helper: rounded ColorRect via StyleBoxFlat ────────────────────────────────
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
