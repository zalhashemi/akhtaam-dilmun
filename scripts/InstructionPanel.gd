extends CanvasLayer

signal start_pressed

var _en_text: String = ""
var _ar_text: String = ""
var _crop_legend: Array = []


func setup(en_text: String, ar_text: String) -> void:
	_en_text = en_text
	_ar_text = ar_text


func set_crop_legend(items: Array) -> void:
	_crop_legend = items


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	var is_ar := Global.current_locale == "ar"
	var text := _ar_text if is_ar else _en_text

	if is_ar:
		text = text.replace("\n\n", "\n")

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.06, 0.80)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.layout_mode = 1
	add_child(bg)

	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.layout_mode = 1
	add_child(root)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.layout_mode = 1
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(margin)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 20)
	margin.add_child(outer)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 24 + (Global.ARABIC_SIZE_BONUS if is_ar else 0))
	lbl.add_theme_color_override("font_color", Color.WHITE)
	if is_ar:
		lbl.layout_direction = Control.LAYOUT_DIRECTION_RTL
		lbl.text_direction = Control.TEXT_DIRECTION_RTL
		if Global.arabic_font != null:
			lbl.add_theme_font_override("font", Global.arabic_font)
	else:
		lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
		lbl.text_direction = Control.TEXT_DIRECTION_LTR
	content.add_child(lbl)

	if not _crop_legend.is_empty():
		var legend_row := HBoxContainer.new()
		legend_row.alignment = BoxContainer.ALIGNMENT_CENTER
		legend_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		legend_row.add_theme_constant_override("separation", 40)
		outer.add_child(legend_row)
		for item in _crop_legend:
			var col := VBoxContainer.new()
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			legend_row.add_child(col)
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(item["path"])
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(80, 80)
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			col.add_child(tex_rect)
			var name_lbl := Label.new()
			name_lbl.text = item["ar_label"] if is_ar else item["en_label"]
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_color_override("font_color", Color.WHITE)
			name_lbl.add_theme_font_size_override("font_size", 18 + (Global.ARABIC_SIZE_BONUS if is_ar else 0))
			if is_ar and Global.arabic_font != null:
				name_lbl.add_theme_font_override("font", Global.arabic_font)
				name_lbl.text_direction = Control.TEXT_DIRECTION_RTL
			col.add_child(name_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(btn_row)

	var btn := Button.new()
	btn.text = "ابدأ" if is_ar else "Start"
	btn.custom_minimum_size = Vector2(200, 64)
	btn.add_theme_font_size_override("font_size", 24 + (Global.ARABIC_SIZE_BONUS if is_ar else 0))
	if is_ar:
		btn.text_direction = Control.TEXT_DIRECTION_RTL
		if Global.arabic_font != null:
			btn.add_theme_font_override("font", Global.arabic_font)
	btn.pressed.connect(_on_start_pressed)
	btn_row.add_child(btn)


func _on_start_pressed() -> void:
	get_tree().paused = false
	start_pressed.emit()
	queue_free()
