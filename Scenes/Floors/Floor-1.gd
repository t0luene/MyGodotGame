extends Node2D

@onready var scene_container = $SceneContainer
@onready var checklist_ui = $CanvasLayer/ChecklistUI

var current_room: Node = null

func _ready():
	# Set current floor in Global
	Global.set_floor("floor-1")

	# Start with hallway
	load_room("res://Scenes/Rooms/Hallway-1.tscn")

	# Connect elevator button


func load_room(path: String):
	var room_scene = load(path)
	if not room_scene:
		push_error("Failed to load room scene: " + path)
		return

	# Remove previous room
	if current_room:
		current_room.queue_free()

	# Instantiate new room
	current_room = room_scene.instantiate()
	scene_container.add_child(current_room)

	# Mark quest completion based on room loaded
	match current_room.name:
		"Hallway-1":
			Global.mark_completed("floor-1", "hallway")
		"Maintenance":
			Global.mark_completed("floor-1", "maintenance_room")
		"Crew":  # optional: if you have separate crew nodes/room
			Global.mark_completed("floor-1", "talk_to_crew")

	# Rebuild checklist UI
	if checklist_ui:
		checklist_ui.rebuild()
