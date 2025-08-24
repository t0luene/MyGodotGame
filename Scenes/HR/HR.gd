extends Node2D

@onready var exit_to_hallway = $ExitToHallway
@onready var interact_button = $InteractButton
@onready var spawn = $SpawnPoint
var player: Node2D = null

func _ready():
	interact_button.pressed.connect(_on_interact_pressed)
	player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = spawn.global_position
	else:
		push_error("⚠️ Player not found in Hallway0")

	exit_to_hallway.body_entered.connect(_on_exit_door)
	print("Hallway0 ready, player at spawn:", player.global_position if player else "null")
	QuestManager.player_entered_hr()


func _on_exit_door(body):
	if body.name == "Player":
		print("Exit Hallway → Boss triggered")
		get_node("/root/NEWGame").load_scene("res://Scenes/Rooms/Hallway0.tscn")

func _on_interact_pressed():
	print("Quest4: Talked to HR")
	QuestManager.complete_requirement(3, 0)  # talk_hr done

	# Show dialogue in HUD
	var dialogue_node = get_node("/root/NEWGame/HUD/CanvasLayer/Dialogue")
	dialogue_node.start([
		{"speaker": "HR", "text": "All your paperwork is done!"}
	])
