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




var quest_dialogues = {
	2: {0: [
			{"speaker": "Boss", "text": "Hello! I need you to walk to that point over there."},
			{"speaker": "Player", "text": "Got it!"}
		]},
	4: {0: [
			{"speaker": "Boss", "text": "Maintenance is acting up. Please go help them."},
			{"speaker": "Player", "text": "On it!"}
		]},
	5: {0: [
			{"speaker": "Boss", "text": "Great work so far! Now I want you to visit the Grid room in floor -2."},
			{"speaker": "Boss", "text": "Talk to the Navigator there and learn everything you need."}
		]},
	6: {0: [
			{"speaker": "Boss", "text": "Great work so far! Now I want you to visit the Grid room on floor -2."},
			{"speaker": "Boss", "text": "Talk to the Navigator there and learn everything you need."}
		]},
	7: {
		0: [
			{"speaker": "Boss", "text": "Ah, it's time to start a new work day. Are you ready?"},
			{"speaker": "Player", "text": "Yes, let's go!"}
		],
		1: [],  # no dialogue, step happens automatically
		2: [
			{"speaker": "Boss", "text": "It's a new day! Let's make it productive."},
			{"speaker": "Player", "text": "On it!"}
		]
	},
	8: {0: [
			{"speaker": "Boss", "text": "We need you to check on the Maintenance Lead. Go talk to them."},
			{"speaker": "Player", "text": "Got it!"}
		]},
	10: {
		4: [  # Task 4 dialogue
			{"speaker": "Boss", "text": "Great! Now that you learned everything, you can now inspect floors, hire employees, assign employees and help our business grow!"},
			{"speaker": "Player", "text": "Yes sir..."},
			{"speaker": "Boss", "text": "Well, what are you waiting for? Whenever you are ready, start the next business day!"}
		]
	}
}



func _on_interact_pressed():
	print("Starting dialogue with Boss")

	var quest_id = QuestManager.current_quest_id
	var req_index = QuestManager.get_current_requirement_index() # first incomplete requirement

	# Handle Quest7 automatic step for new day
	if quest_id == 7 and req_index == 1:
		QuestManager.quest7_new_day()
		return

	# Automatically complete "talk_to_boss" requirements if the current step is that type
	var current_req = QuestManager.quests[quest_id]["requirements"][req_index]
	if current_req["type"] == "talk_to_boss":
		QuestManager.player_talked_to_boss()

		# ✅ New: For Quest10, also complete task 4 (requirement index 4)
		if quest_id == 10 and not QuestManager.quests[10]["requirements"][4]["completed"]:
			QuestManager.complete_requirement(10, 4)

	# Fetch dialogue lines from our quest_dialogues map
	var dialogue_lines = quest_dialogues.get(quest_id, {}).get(req_index, [])
	if dialogue_lines.size() > 0:
		var dialogue = HUD.get_node("CanvasLayer/Dialogue")
		dialogue.start(dialogue_lines)
