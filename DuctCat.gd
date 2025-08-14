extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim = $AnimatedSprite2D


func _ready():
	anim.play("idle")
	add_to_group("duct_cat")
	
func _physics_process(delta):
	var dir = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = dir.normalized() * speed
	move_and_slide()

func exit_duct(exit_position: Vector2):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Move and show player
		player.global_position = exit_position
		player.show()
		player.set_physics_process(true)

		# Camera follows player again
		var floor_script = get_tree().current_scene
		floor_script.camera_target = player

	queue_free()

func _process(delta):
	if $XRayOverlay: # or get_node("XRayOverlay")
		var screen_size = get_viewport_rect().size
		var norm_pos = global_position / screen_size
		$XRayOverlay.material.set_shader_parameter("cat_position", norm_pos)
