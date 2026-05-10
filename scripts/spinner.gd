extends Node2D

var angle: float = 0.0
var label_text: String = "Loading."

func _process(delta: float) -> void:
	angle += delta * 300.0
	if angle >= 360.0:
		angle -= 360.0
	queue_redraw()

func _draw() -> void:
	var center = get_viewport_rect().size / 2
	var radius: float = 40.0
	var thickness: float = 6.0

	draw_arc(center, radius, 0, TAU, 64, Color(0.949, 0.725, 0.514, 0.25), thickness, true)

	var start_angle = deg_to_rad(angle) - PI / 2
	draw_arc(center, radius, start_angle, start_angle + (TAU * 0.28), 32, Color(0.949, 0.725, 0.514, 1.0), thickness, true)

	var font = ThemeDB.fallback_font
	var font_size: int = 24
	var text_pos: Vector2 = center + Vector2(-60, radius + 46)
	draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 1.0))
