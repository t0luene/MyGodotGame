extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var entrance1: Area2D = $Entrance1  # leads to Room3
@onready var entrance2: Area2D = $Entrance2  # leads to Room4
@onready var checklist_trigger = $ChecklistTrigger
@onready var elevator_trigger: Area2D = $ElevatorTrigger  # the proximity trigger for elevator

func _ready():
	# Connect entrances
	entrance1.body_entered.connect(func(body):
		_on_entrance_entered(body, "Room3.tscn")
	)
	entrance2.body_entered.connect(func(body):
		_on_entrance_entered(body, "Room4.tscn")
	)

	# Connect checklist trigger
	checklist_trigger.body_entered.connect(_on_checklist_trigger)

	# Connect elevator proximity trigger
	elevator_trigger.body_entered.connect(_on_elevator_triggered)
	elevator_trigger.visible = false
	elevator_trigger.monitoring = false

	Fade.fade_in(0.5)

func _process(_delta):
	elevator_trigger.visible = true
	elevator_trigger.monitoring = true

func _on_elevator_triggered(body):
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	get_tree().change_scene_to_file("res://Building.tscn")

	
func _on_checklist_trigger(body):
	if body.name != "Player":
		return

	# Mark Hallway1 quest done
	Global.mark_completed("floor4", "hallway1")

# Handler for entrance triggers
func _on_entrance_entered(body, target_room: String) -> void:
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Directly tell Floor4 to load the room
	get_parent().get_parent().load_room(target_room)
