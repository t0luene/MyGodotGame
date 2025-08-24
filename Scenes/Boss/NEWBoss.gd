extends Node2D

@onready var exit_trigger = $ExitToHallway
@onready var walk_trigger = $TriggerArea  # Area2D for Quest1
@onready var interact_button = $InteractButton

func _ready():
	exit_trigger.body_entered.connect(_on_exit_trigger)
	walk_trigger.body_entered.connect(_on_walk_trigger)
	interact_button.pressed.connect(_on_interact_pressed)

# Quest3: Exit Boss → Hallway0
func _on_exit_trigger(body):
	if body.name == "Player":
		print("Exit Boss → Hallway triggered")
		QuestManager.player_exited_boss()
		get_node("/root/NEWGame").load_scene("res://Scenes/Rooms/Hallway0.tscn")

# Quest1: Walk trigger in Boss room
func _on_walk_trigger(body):
	if body.name == "Player":
		print("Walk trigger for Quest1 completed")
		QuestManager.player_walked_to_trigger()
		walk_trigger.queue_free()

func _on_interact_pressed():
	print("Starting dialogue with Boss")
	
	# Complete the appropriate requirement depending on the active quest
	QuestManager.player_talked_to_boss()  # ✅ works for Quest2 and Quest5
	
	# Prepare dialogue lines (customize as needed)
	var dialogue_lines = [
		{"speaker": "Boss", "text": "Hello, player!"},
		{"speaker": "Player", "text": "Got it!"}
	]

	# Show dialogue in HUD
	var dialogue = HUD.get_node("CanvasLayer/Dialogue")
	dialogue.start(dialogue_lines)
