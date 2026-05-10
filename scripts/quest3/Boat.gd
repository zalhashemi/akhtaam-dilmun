extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()

	var screen_size = get_viewport_rect().size
	var half_w = $CollisionShape2D.shape.radius
	var half_h = $CollisionShape2D.shape.height / 2.0
	position.x = clamp(position.x, half_w, screen_size.x - half_w)
	position.y = clamp(position.y, half_h, screen_size.y - half_h)
