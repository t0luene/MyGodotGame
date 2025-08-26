extends Node2D

@onready var exit_to_hallway = $ExitToHallway
@onready var walk_trigger = $TriggerArea  # Area2D for Quest1
@onready var interact_button = $InteractButton
@onready var new_day_button = $NewDayButton


func _ready():
	exit_to_hallway.body_entered.connect(_on_exit_door)
	walk_trigger.body_entered.connect(_on_walk_trigger)
	interact_button.pressed.connect(_on_interact_pressed)
	new_day_button.pressed.connect(_on_new_day_pressed)
	Fade.fade_in(0.5)
	
func _on_new_day_pressed():
	load_subpage("res://Scenes/Globals/NewDay.tscn")
		
func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		$ContentContainer.add_child(instance)


func _on_exit_door(body):
	if body.name != "Player":
		return

	print("Exit Boss → Hallway0 triggered")

	# Grid is inside SceneContainer which is inside Floor-2
	var floor0_root = get_parent().get_parent()  
	if floor0_root and floor0_root.has_method("load_room"):
		floor0_root.load_room("res://Scenes/Rooms/Hallway0.tscn")
	else:
		push_error("Cannot find Floor0 root to load Hallway0")
		
		

# Quest1: Walk trigger in Boss room
func _on_walk_trigger(body):
	if body.name == "Player":
		print("Walk trigger for Quest1 completed")
		QuestManager.player_walked_to_trigger()
		walk_trigger.queue_free()

func _on_interact_pressed():
	print("Starting dialogue with Boss")
	
	# Complete the quest requirement
	QuestManager.player_talked_to_boss()  

	var dialogue_lines = []

	match QuestManager.current_quest_id:
		2: # Quest2
			dialogue_lines = [
				{"speaker": "Boss", "text": "Hello! I need you to walk to that point over there."},
				{"speaker": "Player", "text": "Got it!"}
			]
		4: # Quest5
			dialogue_lines = [
				{"speaker": "Boss", "text": "Maintenance is acting up. Please go help them."},
				{"speaker": "Player", "text": "On it!"}
			]
		5: # Quest6
			dialogue_lines = [
				{"speaker": "Boss", "text": "Great work so far! Now I want you to visit the Grid room in floor -2."},
				{"speaker": "Boss", "text": "Talk to the Navigator there and learn everything you need."}
			]
		6: # Quest6
			dialogue_lines = [
				{"speaker": "Boss", "text": "Great work so far! Now I want you to visit the Grid room on floor -2."},
				{"speaker": "Boss", "text": "Talk to the Navigator there and learn everything you need."}
			]
		_: 
			dialogue_lines = [
				{"speaker": "Boss", "text": "Hello, player!"}
			]

	# Show dialogue
	var dialogue = HUD.get_node("CanvasLayer/Dialogue")
	dialogue.start(dialogue_lines)
