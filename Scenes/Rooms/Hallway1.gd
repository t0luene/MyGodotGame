extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var entrance1: Area2D = $Entrance1  # leads to Room1A
@onready var entrance2: Area2D = $Entrance2  # leads to Room1B
@onready var hallway_trigger: Area2D = $HallwayTrigger
@onready var crew_stairs_button = $UI/CrewStairsButton
@onready var inspect_elevator_button = $UI/InspectElevatorButton
signal inspection_complete(floor_index)

func _ready():
	# existing connections
	entrance1.body_entered.connect(func(body):
		_on_entrance_entered(body, "Scenes/Rooms/Room1A.tscn")
	)
	entrance2.body_entered.connect(func(body):
		_on_entrance_entered(body, "Scenes/Rooms/Room1B.tscn")
	)
	hallway_trigger.body_entered.connect(_on_hallway_trigger)
	
	# new button connections
	if crew_stairs_button:
		crew_stairs_button.pressed.connect(_on_crew_stairs_pressed)
	else:
		push_error("CrewStairsButton not found!")

	if inspect_elevator_button:
		inspect_elevator_button.pressed.connect(_on_inspect_elevator_pressed)
	else:
		push_error("InspectElevatorButton not found!")

	Fade.fade_in(0.5)



# -------------------------
# Hallway inspection trigger
# -------------------------
func _on_hallway_trigger(body):
	if body.name != "Player":
		return

	# ✅ Quest 9, task 2 = inspect_hallway1
	if QuestManager.current_quest_id == 9:
		QuestManager.complete_requirement(9, 2)
		print("✅ Quest 9 Task 2 complete: inspect_hallway1")



# -------------------------
# Elevator inspection button
# -------------------------
func _on_inspect_elevator_pressed():
	if QuestManager.current_quest_id == 9:
		QuestManager.complete_requirement(9, 3)  # Task: inspect_elevator
		print("✅ Quest 9 Task 3 complete: inspect_elevator")

		# Show dialogue
		var dialogue_node = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
		if dialogue_node:
			dialogue_node.start([
				{"speaker": "Player", "text": "Huh, seems broken."}
			])
		else:
			push_error("Dialogue node not found!")



# -------------------------
# Entering rooms
# -------------------------
func _on_entrance_entered(body, target_room: String) -> void:
	if body.name != "Player":
		return

	# Fade out
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Load the room into the current floor
	get_parent().get_parent().load_room(target_room)

	# Auto-mark room inspection tasks
	match target_room:
		"res://Scenes/Rooms/Room1A.tscn":
			if Global.quest9_tasks[4]["completed"] == false:
				Global.quest9_tasks[4]["completed"] = true
				print("✅ Quest 9 Task 4 complete: inspect_room1a")
		"res://Scenes/Rooms/Room1B.tscn":
			if Global.quest9_tasks[5]["completed"] == false:
				Global.quest9_tasks[5]["completed"] = true
				print("✅ Quest 9 Task 5 complete: inspect_room1b")


# -------------------------
# Crew stairs button
# -------------------------
func _on_crew_stairs_pressed():
	print("🔹 CrewStairsButton pressed")

	# Ensure building floors exist
	Global.ensure_building_floors_initialized()

	# Mark Floor1 READY in Global
	var floor = Global.building_floors[0]
	floor["state"] = Global.FloorState.READY
	Global.building_floors[0] = floor
	print("✅ Floor1 marked READY via Global")

	# Fade out if you have a fade system
	if Fade.has_method("fade_out"):
		Fade.fade_out(0.5)
		await get_tree().create_timer(0.5).timeout

	# Go back to Maintenance scene
	var maintenance_scene = load("res://Scenes/Maintenance/Maintenance.tscn")
	if maintenance_scene:
		print("🔹 Changing scene to Maintenance")
		get_tree().change_scene_to_packed(maintenance_scene)
	else:
		push_error("❌ Failed to load Maintenance.tscn")
