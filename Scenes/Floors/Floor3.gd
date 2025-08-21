extends Node2D

@onready var scene_container = $SceneContainer

var current_room: Node = null

func _ready():
	Global.set_floor("floor3")
	load_room("Scenes/Rooms/Hallway2.tscn")  # always start with Hallway1

func load_room(path: String):
	var room_scene = load(path)
	if not room_scene:
		push_error("Failed to load room scene: " + path)
		return

	if current_room:
		current_room.queue_free()

	current_room = room_scene.instantiate()
	scene_container.add_child(current_room)
	# Rebuild checklist after marking quest
	var checklist_ui = $CanvasLayer/ChecklistUI
	if checklist_ui:
		checklist_ui.rebuild()


	# Mark quest completion (optional: can also do inside rooms)
	match current_room.name:
		"Hallway2":
			Global.mark_completed("floor3", "hallway2")
		"Room1":
			Global.mark_completed("floor3", "room1")
