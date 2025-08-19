extends Control

func _ready():
	$HiringButton.pressed.connect(_on_hiring_button_pressed)
	$StaffButton.pressed.connect(_on_staff_button_pressed)
	$BulletinBoardButton.pressed.connect(_on_bulletin_board_button_pressed)
	$BackButton.pressed.connect(_on_back_button_presssed)

	# Load HiringPage by default when EM opens
	load_subpage("res://Scenes/HR/Hiring.tscn")

func _on_hiring_button_pressed():
	load_subpage("res://Scenes/HR/Hiring.tscn")
	
func _on_bulletin_board_button_pressed():
	load_subpage("res://Scenes/HR/BulletinBoard.tscn")

func _on_staff_button_pressed():
	load_subpage("res://Scenes/HR/Staff.tscn")

func _on_back_button_presssed():
	get_tree().change_scene_to_file("res://Game.tscn")
		
func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		$ContentContainer.add_child(instance)
