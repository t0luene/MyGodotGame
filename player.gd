extends CharacterBody2D

@export var move_speed := 150.0
@onready var anim := $AnimatedSprite2D  # Update this path if your sprite has a different name or location
@export var allow_vertical_movement: bool = true

func _ready():
	if has_node("Camera2D"):
		$Camera2D.make_current()


var can_move := true  # Add this at the top of your script (if not already)

func _physics_process(delta):
	if not can_move:
		# Gradually reduce velocity towards zero for smooth slowdown
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)  # tweak 500 for speed of slowdown
		move_and_slide()
		
		# Switch to idle when almost stopped
		if velocity.length() < 1.0:
			velocity = Vector2.ZERO
			if anim.animation != "idle":
				anim.play("idle")
		return

	# Normal movement code...

	var direction := Vector2.ZERO

	# Get horizontal input
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	# Get vertical input if allowed
	if allow_vertical_movement:
		direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# Apply movement if input detected
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

	# Determine dominant direction
	var abs_x = abs(velocity.x)
	var abs_y = abs(velocity.y)

	if allow_vertical_movement and abs_y > abs_x:
		# Vertical movement
		if velocity.y < 0:
			if anim.animation != "walk_up":
				anim.play("walk_up")
		else:
			if anim.animation != "walk_down":
				anim.play("walk_down")
	else:
		# Horizontal movement
		if anim.animation != "walk":
			anim.play("walk")
		anim.flip_h = velocity.x < 0
