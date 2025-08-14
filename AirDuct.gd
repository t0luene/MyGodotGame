extends Area2D

@export var duct_cat_scene: PackedScene
@onready var enter_button = $EnterButton
@onready var exit_button = $ExitTrigger/ExitButton
@onready var spawn_point = $SpawnPoint
var player_in_range: bool = false
var duct_cat_inside: CharacterBody2D = null


func _ready():
	enter_button.visible = false  # hide initially
	exit_button.visible = false
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	enter_button.connect("pressed", Callable(self, "_on_enter_pressed"))
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))


func _on_body_entered(body):
	if body.is_in_group("player") and duct_cat_inside == null:
		player_in_range = true
		enter_button.visible = true


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		enter_button.visible = false


func _on_enter_pressed():
	if not player_in_range:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.hide()
		player.set_physics_process(false)

	# Spawn DuctCat
	var duct_cat = duct_cat_scene.instantiate()
	duct_cat.position = spawn_point.global_position
	get_tree().current_scene.add_child(duct_cat)
	duct_cat_inside = duct_cat

	# Camera now follows the moving DuctCat
	var floor_script = get_tree().current_scene
	floor_script.camera_target = duct_cat

	# Enable X-Ray
	set_xray(true)

	enter_button.visible = false
	exit_button.visible = true


func _on_exit_pressed():
	if duct_cat_inside:
		duct_cat_inside.exit_duct(global_position)
		duct_cat_inside = null
		exit_button.visible = false
		enter_button.visible = true

		# Disable X-Ray
	set_xray(false)


# Helper function to toggle X-Ray effect
func set_xray(enabled: bool):
	var xray = get_tree().current_scene.get_node("XRay")
	if xray:
		xray.visible = enabled
		if xray.material:
			xray.material.set_shader_parameter("effect_enabled", enabled)
