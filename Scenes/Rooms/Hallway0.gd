extends Node2D

@onready var exit_to_boss = $ExitToBoss
@onready var hr_door = $Entrance1
@onready var boss_door = $Entrance2
@onready var spawn = $SpawnPoint
@onready var elevator_trigger: Area2D = $ElevatorTrigger

var player: Node2D = null

func _ready():
	if QuestManager.current_quest_id == 2:
		# Task 1 = enter_hr
		QuestManager.complete_requirement(2, 0)
		print("✅ Quest 2 Task 'enter_hr' complete")
	hr_door.body_entered.connect(func(body):
		_on_entrance_entered(body, "res://Scenes/HR/HR.tscn")
	)
	boss_door.body_entered.connect(func(body):
		_on_entrance_entered(body, "res://Scenes/Boss/NEWBoss.tscn")
	)
	player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = spawn.global_position
	else:
		push_error("⚠️ Player not found in Hallway0")

	elevator_trigger.body_entered.connect(_on_elevator_triggered)
	elevator_trigger.visible = false
	elevator_trigger.monitoring = false

func _process(_delta):
	elevator_trigger.visible = true
	elevator_trigger.monitoring = true

func _on_elevator_triggered(body):
	if body.name != "Player":
		return

	# Unified elevator handling for multiple quests
	if QuestManager.current_quest_id in [4, 5]:
		QuestManager.player_entered_elevator()

	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")




func _on_entrance_entered(body, target_room: String) -> void:
	if body.name != "Player":
		return
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_parent().get_parent().load_room(target_room)
