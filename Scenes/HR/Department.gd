extends Node2D

@onready var exit_to_hallway: Area2D = $ExitToHallway
@onready var interact_button: Button = $InteractButton

# Track selection state for each PNG
var selected = {
	"tower": false,
	"tech": false,
	"management": false,
	"inspection": false
}

func _ready():
	# Ensure exit trigger works
	exit_to_hallway.monitoring = true
	exit_to_hallway.visible = false
	exit_to_hallway.body_entered.connect(_on_exit_door)

	# Print floor root for debugging
	var floor_root = get_parent().get_parent()
	print("Floor root:", floor_root)

	# Connect interact button
	interact_button.pressed.connect(_on_interact_pressed)

	# Fade in
	Fade.fade_in(0.5)

	# Quest step
	if QuestManager.current_quest_id == 4:
		QuestManager.enter_maint_room()

	# Connect clicks for subpages
	$TowerImage.gui_input.connect(_on_tower_input)
	$TechTreeImage.gui_input.connect(_on_tech_input)
	$ManagementImage.gui_input.connect(_on_management_input)
	$InspectionImage.gui_input.connect(_on_inspection_input)

	# Connect hover glow
	$TowerImage.mouse_entered.connect(func(): _set_hover($TowerImage, true))
	$TowerImage.mouse_exited.connect(func(): _set_hover($TowerImage, false))
	$TechTreeImage.mouse_entered.connect(func(): _set_hover($TechTreeImage, true))
	$TechTreeImage.mouse_exited.connect(func(): _set_hover($TechTreeImage, false))
	$ManagementImage.mouse_entered.connect(func(): _set_hover($ManagementImage, true))
	$ManagementImage.mouse_exited.connect(func(): _set_hover($ManagementImage, false))
	$InspectionImage.mouse_entered.connect(func(): _set_hover($InspectionImage, true))
	$InspectionImage.mouse_exited.connect(func(): _set_hover($InspectionImage, false))

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
				_set_hover(other_node, false)
				selected[other_key] = false

		# Highlight this node
		_highlight(node, true)
		selected[key] = true
	else:
		# Go to subpage on second click
		_highlight(node, false)
		_set_hover(node, false)
		selected[key] = false
		load_subpage(path)

# ---------- Helpers ----------
func _highlight(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("outline_enabled", enable)

func _set_hover(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("glow_enabled", enable)

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
		Global.clear_children($ContentContainer)
		if instance is Window:
			get_tree().current_scene.add_child(instance)
		else:
			$ContentContainer.add_child(instance)

# ---------- Exit door ----------
func _on_exit_door(body):
	print("Something entered exit trigger:", body.name)
	if body.name != "Player":
		return

	print("Exit Maintenance → Hallway-1 triggered")

	var floor_root = get_parent().get_parent()
	if floor_root and floor_root.has_method("load_room"):
		floor_root.load_room("res://Scenes/Rooms/Hallway-1.tscn")
		print("Room loaded, current_room:", floor_root.current_room)
		# Reset position and visibility
		if floor_root.current_room:
			floor_root.current_room.position = Vector2.ZERO
			floor_root.current_room.visible = true
	else:
		push_error("Cannot find floor root to load Hallway-1")

# ---------- Interact ----------
func _on_interact_pressed():
	print("Quest5: Talked to MaintLead")
	QuestManager.complete_requirement(4, 5)

	var dialogue_node = get_node("/root/HUD/CanvasLayer/Dialogue")
	dialogue_node.start([
		{"speaker": "MaintLead", "text": "All your paperwork is done!"}
	])
