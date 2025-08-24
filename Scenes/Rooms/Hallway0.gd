extends Node2D

@onready var exit_to_boss = $ExitToBoss
@onready var hr_door = $Entrance1
@onready var boss_door = $Entrance2
@onready var spawn = $SpawnPoint
@onready var elevator_trigger: Area2D = $ElevatorTrigger

var player: Node2D = null

func _ready():
	player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = spawn.global_position
	else:
		push_error("⚠️ Player not found in Hallway0")

	boss_door.body_entered.connect(_on_boss_door)
	hr_door.body_entered.connect(_on_hr_door)
	elevator_trigger.body_entered.connect(_on_elevator_triggered)
	elevator_trigger.visible = false
	elevator_trigger.monitoring = false

func _process(_delta):
	elevator_trigger.visible = true
	elevator_trigger.monitoring = true

func _on_elevator_triggered(body):
	if body.name != "Player":
		return

	if QuestManager.current_quest_id == 4:
		QuestManager.player_entered_elevator_maint()

	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")

func _on_boss_door(body):
	if body.name == "Player":
		print("Exit Hallway → Boss triggered")
		get_node("/root/NEWGame").load_scene("res://Scenes/Boss/NEWBoss.tscn")

func _on_hr_door(body):
	if body.name == "Player":
		print("Exit Hallway → HR triggered")
		QuestManager.player_exited_boss()
		get_node("/root/NEWGame").load_scene("res://Scenes/HR/HR.tscn")
