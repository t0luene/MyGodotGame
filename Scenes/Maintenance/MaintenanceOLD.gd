extends Control


func _ready():
	Fade.fade_in(0.5)
	$TowerButton.pressed.connect(_on_tower_button_pressed)
	$TechTreeButton.pressed.connect(_on_tech_tree_button_pressed)
	$ManagementButton.pressed.connect(_on_management_button_pressed)
	$InspectionButton.pressed.connect(_on_inspection_button_presssed)
	$BackButton.pressed.connect(_on_back_button_presssed)

	# Load Tower page by default
	_on_tower_button_pressed()

func _on_tower_button_pressed():
	load_subpage("res://Scenes/Maintenance/Tower.tscn")

func _on_tech_tree_button_pressed():
	load_subpage("res://Scenes/Maintenance/TechTree.tscn")

func _on_management_button_pressed():
	load_subpage("res://Scenes/Maintenance/Management.tscn")

func _on_inspection_button_presssed():
	load_subpage("res://Floor1Inspection.tscn")

func _on_back_button_presssed():
	get_tree().change_scene_to_file("res://Game.tscn")
		
	
func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		$ContentContainer.add_child(instance)
