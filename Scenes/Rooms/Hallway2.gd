extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var entrance1: Area2D = $Entrance1  # leads to Room2A
@onready var checklist_trigger: Area2D = $ChecklistTrigger
@onready var crew_stairs_button = $UI/CrewStairsButton
@onready var elevator_trigger: Area2D = $ElevatorTrigger  # proximity trigger for elevator

signal inspection_complete(floor_index)

func _ready():
	# Entrance triggers
	entrance1.body_entered.connect(func(body):
		_on_entrance_entered(body, "res://Scenes/Rooms/Room2A.tscn")
	)

	# Checklist trigger
	checklist_trigger.body_entered.connect(_on_checklist_trigger)

	# Elevator trigger
	elevator_trigger.body_entered.connect(_on_elevator_triggered)

	# Crew stairs button
	if crew_stairs_button:
		crew_stairs_button.pressed.connect(_on_crew_stairs_pressed)
	else:
		push_error("CrewStairsButton not found!")

	Fade.fade_in(0.5)


# -------------------------
# Entrance to rooms
# -------------------------
func _on_entrance_entered(body, target_room: String) -> void:
	if body.name != "Player":
		return

	# Fade out
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Load the room into the current floor
	get_parent().get_parent().load_room(target_room)


# -------------------------
# Checklist trigger
# -------------------------
func _on_checklist_trigger(body):
	if body.name != "Player":
		return

	# Mark hallway inspection done for Floor2
	Global.mark_completed("floor2", "hallway2")


# -------------------------
# Elevator trigger
# -------------------------
func _on_elevator_triggered(body):
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")


# -------------------------
# Crew stairs button
# -------------------------
# inside Hallway2.gd
func _on_crew_stairs_pressed():
	print("🔹 CrewStairsButton pressed")

	Global.ensure_building_floors_initialized()

	# Mark Floor2 READY
	var floor = Global.building_floors[1]
	floor["state"] = Global.FloorState.READY
	Global.building_floors[1] = floor
	print("✅ Floor2 marked READY via Global")

	# Fade out
	if Fade.has_method("fade_out"):
		Fade.fade_out(0.5)
		await get_tree().create_timer(0.5).timeout

	# Correctly call load_room() on the Floor2 node
	var floor_node = get_tree().current_scene
	if floor_node and floor_node.has_method("load_room"):
		floor_node.load_room("res://Scenes/Maintenance/Maintenance.tscn")
	else:
		push_error("❌ Floor2 node missing load_room() method")
