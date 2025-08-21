extends Control

@onready var elevator_trigger: Area2D = $ElevatorTrigger  # the proximity trigger for elevator
@onready var exit_to_hallway: Area2D = $ExitToHallway  # doorway back to Hallway1


# Track selection state for each PNG
var selected = {
	"tower": false,
	"tech": false,
	"management": false,
	"inspection": false
}

func _ready():
	Global.mark_completed("floor-1", "maintenance_room")
	Fade.fade_in(0.5)
	elevator_trigger.body_entered.connect(_on_elevator_triggered)
	elevator_trigger.visible = false
	elevator_trigger.monitoring = false
	exit_to_hallway.body_entered.connect(_on_exit_entered)
	# Connect clicks
	$TowerImage.gui_input.connect(_on_tower_input)
	$TechTreeImage.gui_input.connect(_on_tech_input)
	$ManagementImage.gui_input.connect(_on_management_input)
	$InspectionImage.gui_input.connect(_on_inspection_input)
	$BackButton.pressed.connect(_on_back_button_pressed)

	# Connect hover for glow
	$TowerImage.mouse_entered.connect(func(): _set_hover($TowerImage, true))
	$TowerImage.mouse_exited.connect(func(): _set_hover($TowerImage, false))

	$TechTreeImage.mouse_entered.connect(func(): _set_hover($TechTreeImage, true))
	$TechTreeImage.mouse_exited.connect(func(): _set_hover($TechTreeImage, false))

	$ManagementImage.mouse_entered.connect(func(): _set_hover($ManagementImage, true))
	$ManagementImage.mouse_exited.connect(func(): _set_hover($ManagementImage, false))

	$InspectionImage.mouse_entered.connect(func(): _set_hover($InspectionImage, true))
	$InspectionImage.mouse_exited.connect(func(): _set_hover($InspectionImage, false))


func _process(_delta):
	elevator_trigger.visible = true
	elevator_trigger.monitoring = true
	
# ---------- Input handlers ----------
func _on_tower_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("tower", $TowerImage, "res://Scenes/Maintenance/Tower.tscn")

func _on_tech_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("tech", $TechTreeImage, "res://Scenes/Maintenance/TechTree.tscn")

func _on_management_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("management", $ManagementImage, "res://Scenes/Maintenance/Management.tscn")

func _on_inspection_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("inspection", $InspectionImage, "res://Floor1Inspection.tscn")


# ---------- Core click logic ----------
func _handle_click(key: String, node: TextureRect, path: String):
	if not selected[key]:
		# Deselect all other nodes first
		for other_key in selected.keys():
			if other_key != key and selected[other_key]:
				var other_node = get_node_for_key(other_key)
				_highlight(other_node, false)
				_set_hover(other_node, false)  # <-- fixed
				selected[other_key] = false

		# highlight this node
		_highlight(node, true)
		selected[key] = true
	else:
		# go to subpage on second click
		_highlight(node, false)
		_set_hover(node, false)  # <-- fixed
		selected[key] = false
		load_subpage(path)


# ---------- Helpers ----------
func _highlight(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("outline_enabled", enable)

func _set_hover(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("glow_enabled", enable)

# Map key to node
func get_node_for_key(key: String) -> TextureRect:
	match key:
		"tower": return $TowerImage
		"tech": return $TechTreeImage
		"management": return $ManagementImage
		"inspection": return $InspectionImage
		_: return null

func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer) # keep clearing content container for other Control subpages
		if instance is Window:
			get_tree().current_scene.add_child(instance)
		else:
			$ContentContainer.add_child(instance)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Game.tscn")




func _on_elevator_triggered(body):
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")

# Handler for exit trigger
func _on_exit_entered(body) -> void:
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Tell Floor4 to load Hallway1
	get_parent().get_parent().load_room("Scenes/Rooms/Hallway-1.tscn")
