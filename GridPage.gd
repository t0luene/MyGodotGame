extends Control


func _ready():
	$InfoButton.pressed.connect(_on_info_button_pressed)
	$MissionsButton.pressed.connect(_on_missions_button_pressed)
	$TechTreeButton.pressed.connect(_on_tech_tree_button_pressed)	
	$BackButton.pressed.connect(_on_back_button_presssed)	

func _on_info_button_pressed():
	load_subpage("res://GridInfo.tscn")

func _on_missions_button_pressed():
	load_subpage("res://GridMissions.tscn")
	
func _on_tech_tree_button_pressed():
	load_subpage("res://GridTechTree.tscn")
	
func _on_back_button_presssed():
	get_tree().change_scene_to_file("res://Game.tscn")
		
	
func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		$ContentContainer.add_child(instance)
