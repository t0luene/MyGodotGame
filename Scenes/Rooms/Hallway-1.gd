extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var entrance1: Area2D = $Entrance1
@onready var entrance2: Area2D = $Entrance2
@onready var checklist_trigger: Area2D = $ChecklistTrigger
@onready var elevator_trigger: Area2D = $ElevatorTrigger
@export var floor_index: int = 120  # Basement 1 corresponds to Global.building_floors[120]

func _ready():
	print("Hello from Hallway-BM0 (floor_index = %d)" % floor_index)

	entrance1.body_entered.connect(func(body):
		_on_entrance_entered(body, "res://Scenes/Maintenance/Maintenance.tscn")
	)
	entrance2.body_entered.connect(func(body):
		_on_entrance_entered(body, "res://Scenes/Rooms/Crew.tscn")
	)

	checklist_trigger.body_entered.connect(_on_checklist_trigger)
	elevator_trigger.body_entered.connect(_on_elevator_triggered)

	# start elevator trigger disabled
	elevator_trigger.visible = false
	elevator_trigger.monitoring = false

	Fade.fade_in(0.5)

func _process(_delta):
	# allow elevator access after fade
	elevator_trigger.visible = true
	elevator_trigger.monitoring = true

func _on_elevator_triggered(body):
	if body.name != "Player":
		return

	# update global scene reference
	Global.current_floor_scene = Global.building_floors[floor_index]["scene"]
	print("📍 Global.current_floor_scene is:", Global.current_floor_scene)

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")

func _on_checklist_trigger(body):
	if body.name != "Player":
		return
	print("ChecklistTrigger activated in Hallway-BM0")
	if QuestManager.current_quest_id == 4:
		print("Calling QuestManager.player_entered_hallway_BM0()")
		QuestManager.player_entered_hallway_BM0()

func _on_entrance_entered(body, target_room: String) -> void:
	if body.name != "Player":
		return
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_parent().get_parent().load_room(target_room)
