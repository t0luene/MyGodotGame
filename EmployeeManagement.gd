extends Control

func _ready():
	$HiringButton.pressed.connect(_on_hiring_button_pressed)
	$StaffButton.pressed.connect(_on_staff_button_pressed)

func _on_hiring_button_pressed():
	load_subpage("res://HiringPage.tscn")

func _on_staff_button_pressed():
	load_subpage("res://StaffPage.tscn")

func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		$ContentContainer.add_child(instance)
