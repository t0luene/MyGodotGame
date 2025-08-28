extends Node2D

@onready var scene_container = $SceneContainer
var current_room: Node = null

func _ready():
	# Set current floor
	Global.set_floor("floor1")

	# Load initial room
	load_room("res://Scenes/Rooms/Hallway1.tscn")
	
func load_room(path: String):
	var room_scene = load(path)
	if not room_scene:
		push_error("Failed to load room scene: " + path)
		return

	# Remove previous room completely
	if current_room:
		current_room.queue_free()

	# Instantiate and add the new room
	current_room = room_scene.instantiate()
	scene_container.add_child(current_room)

	current_room.position = Vector2.ZERO
	if current_room is Control:
		current_room.rect_position = Vector2.ZERO

	current_room.visible = true
