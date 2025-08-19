extends Node2D

@onready var scene_container = $SceneContainer
@onready var elevator_button: Button = $ElevatorButton

var current_room: Node = null

func _ready():
	Global.set_floor("floor4")
	load_room("Scenes/Rooms/Hallway1.tscn")  # always start with Hallway1

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
		"Hallway1":
			Global.mark_completed("floor4", "hallway1")
		"Room2":
			Global.mark_completed("floor4", "room2")
		"Room3":
			Global.mark_completed("floor4", "room3")
		"Room4":
			Global.mark_completed("floor4", "room4")
