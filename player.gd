extends CharacterBody2D

@export var move_speed := 350.0
@onready var anim := $AnimatedSprite2D  # Update path if needed
@export var allow_vertical_movement: bool = true
@export var player_portrait: Texture2D

var can_move := true
var target_position: Vector2 = Vector2.ZERO
var moving: bool = false

func _ready():
	if has_node("Camera2D"):
		$Camera2D.make_current()

func _unhandled_input(event: InputEvent) -> void:
	# Detect screen taps for mobile
	if event is InputEventScreenTouch and event.pressed:
		set_target_position(event.position)

func set_target_position(pos: Vector2) -> void:
	target_position = pos
	moving = true

func _physics_process(delta):
	if not can_move:
		# Gradual slowdown
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
		move_and_slide()

		if velocity.length() < 1.0:
			velocity = Vector2.ZERO
			if anim.animation != "idle":
				anim.play("idle")
		return

	# --- Mobile Tap-to-Move ---
	if moving:
		var direction = (target_position - global_position)
		if direction.length() > 5:
			velocity = direction.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
			moving = false

		move_and_slide()
		_update_animation()
		return

	# --- Desktop Controls ---
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	if allow_vertical_movement:
		direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_animation()

func _update_animation():
	if velocity.length() == 0:
		if anim.animation != "idle":
			anim.play("idle")
		return

	var abs_x = abs(velocity.x)
	var abs_y = abs(velocity.y)

	if allow_vertical_movement and abs_y > abs_x:
		if velocity.y < 0:
			if anim.animation != "walk_up":
				anim.play("walk_up")
		else:
			if anim.animation != "walk_down":
				anim.play("walk_down")
	else:
		if anim.animation != "walk":
			anim.play("walk")
		anim.flip_h = velocity.x < 0
