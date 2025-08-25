extends Node2D

@onready var exit_to_hallway = $ExitToHallway
@onready var interact_button = $InteractButton

func _ready():
	interact_button.pressed.connect(_on_interact_pressed)
	Fade.fade_in(0.5)

	# Connect exit trigger safely
	exit_to_hallway.body_entered.connect(_on_exit_door)

	# ✅ Give checklist check for entering Grid
	QuestManager.player_entered_grid_room()

	# Buttons
	$InfoButton.pressed.connect(_on_info_button_pressed)
	$MissionsButton.pressed.connect(_on_missions_button_pressed)
	$TechTreeButton.pressed.connect(_on_tech_tree_button_pressed)	

	# Load GridMissions as default page:
	_on_missions_button_pressed()


func _on_info_button_pressed():
	load_subpage("res://GridInfo.tscn")

func _on_missions_button_pressed():
	load_subpage("res://GridMissions.tscn")
	
func _on_tech_tree_button_pressed():
	load_subpage("res://GridTechTree.tscn")
		
func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		$ContentContainer.add_child(instance)


func _on_exit_door(body):
	if body.name != "Player":
		return

	print("Exit Grid → Hallway-2 triggered")

	# Grid is inside SceneContainer which is inside Floor-2
	var floor2_root = get_parent().get_parent()  
	if floor2_root and floor2_root.has_method("load_room"):
		floor2_root.load_room("res://Scenes/Rooms/Hallway-2.tscn")
	else:
		push_error("Cannot find Floor-2 root to load Hallway-2")

func _on_interact_pressed():
	print("Quest5: Talked to GridNavigator")

	# Complete the quest requirement
	QuestManager.complete_requirement(5, 4)  # Quest5: talk_to_grid_navigator

	# Show dialogue via autoloaded HUD safely
	var dialogue_node = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
	if dialogue_node:
		dialogue_node.start([
			{"speaker": "GridNavigator", "text": "All your paperwork is done!"}
		])
	else:
		push_error("⚠️ Dialogue node not found in HUD")
