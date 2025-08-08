extends Node

var current_floor_scene: PackedScene = null
var current_floor_instance: Node = null

func switch_floor(floor_number: int) -> void:
	# Free old floor instance if exists
	if current_floor_instance:
		current_floor_instance.queue_free()
		current_floor_instance = null
	
	# Determine scene path by floor number
	var scene_path = ""
	match floor_number:
		1:
			scene_path = "res://floors/Floor1_Work.tscn"
		2:
			scene_path = "res://floors/Floor2_Training.tscn"
		3:
			scene_path = "res://floors/Floor3_HR.tscn"
		_:
			print("Invalid floor number: %d" % floor_number)
			return

	# Load and instance the scene
	current_floor_scene = load(scene_path)
	current_floor_instance = current_floor_scene.instantiate()
	
	# Add it as child to a container node in your UI (make sure you have one)
	$FloorContainer.add_child(current_floor_instance)
