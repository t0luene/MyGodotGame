extends Node2D

@onready var scene_container = $SceneContainer
var current_room: Node = null

func _ready():
	# Set current floor
	Global.set_floor("floor-1")

	# Load initial room: Hallway-1
	load_room("res://Scenes/Rooms/Hallway-1.tscn")


func _on_exit_request(room_path: String):
	print("Floor-1: received exit request →", room_path)
	load_room(room_path)
	if current_room:
		print("Loaded new room:", current_room.name)
		current_room.position = Vector2.ZERO
		current_room.visible = true


func load_room(path: String):
	var room_scene = load(path)
	if not room_scene:
		push_error("Failed to load room scene: " + path)
		return

	# Clear container
	for child in scene_container.get_children():
		child.queue_free()

	# Instantiate
	current_room = room_scene.instantiate()
	scene_container.add_child(current_room)

	# Reset position
	current_room.position = Vector2.ZERO
	if current_room is Control:
		current_room.rect_position = Vector2.ZERO
	current_room.visible = true

	# 🔹 Connect exit signal if room has it
	if current_room.has_signal("request_exit_to_hallway"):
		# Disconnect previous connection to avoid duplicates
		if current_room.is_connected("request_exit_to_hallway", Callable(self, "_on_exit_request")):
			current_room.disconnect("request_exit_to_hallway", Callable(self, "_on_exit_request"))
		current_room.connect("request_exit_to_hallway", Callable(self, "_on_exit_request"))

	print("Loaded room:", current_room.name)

	# Mark rooms completed
	match current_room.name:
		"Hallway-1":
			Global.mark_completed("floor-1", "hallway-1")
		"Maintenance":
			Global.mark_completed("floor-1", "maintenance_room")
