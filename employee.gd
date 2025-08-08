extends CharacterBody2D

# 🎛️ Tweakable in Inspector
@export var move_speed_min := 30.0
@export var move_speed_max := 60.0
@export var move_range_min := 100.0
@export var move_range_max := 300.0

# 🎞️ Sprite Animation
@onready var anim := $AnimatedSprite2D

# 🧠 Internal state
var current_move_speed := 40.0
var current_move_range := 150.0
var target_position: Vector2 = Vector2.ZERO
var pause_time := 0.0
var employee_index: int = -1
var teleporting := false

func _ready():
	randomize()
	_set_new_target()

func _physics_process(delta):
	if teleporting:
		velocity = Vector2.ZERO
		move_and_slide()
		return  # ⛔ Stop everything else if teleporting is true

	# ⏸ Pause logic
	if pause_time > 0.0:
		pause_time -= delta
		velocity = Vector2.ZERO
	else:
		# 🧭 Movement logic
		var direction = (target_position - global_position).normalized()
		velocity = direction * current_move_speed

		# 🚩 Check if reached target
		if global_position.distance_to(target_position) < 10.0:
			_set_new_target()

	# 🏃 Apply movement
	move_and_slide()

	# 🎞️ Handle animation
	if velocity.length() > 1.0:
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "idle":
			anim.play("idle")

	# Flip sprite based on direction
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0

		
func _set_new_target():
	# 🎲 Randomize speed and range
	current_move_speed = randf_range(move_speed_min, move_speed_max)
	current_move_range = randf_range(move_range_min, move_range_max)

	# ↔️ Choose new X offset (Y stays same)
	var x_offset = randf_range(-current_move_range, current_move_range)
	target_position = Vector2(global_position.x + x_offset, global_position.y)

	# ⏱ Random pause before next move
	pause_time = randf_range(1.0, 3.0)
