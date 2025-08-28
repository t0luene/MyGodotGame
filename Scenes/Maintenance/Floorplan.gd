extends Window

const FLOOR_COST = 300

@export var inspected_floor_index: int = -1
@onready var floors_container = $Tower/FloorsContainer
@onready var money_label = $Tower/MoneyLabel
@export var max_capacity := 4

var selected_floor_index = -1  # no floor selected initially
var current_manage_index: int = -1
var selected_slot := -1

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)

	Global.ensure_building_floors_initialized()


	selected_floor_index = -1
	current_manage_index = -1
	selected_slot = -1
	inspected_floor_index = Global.current_inspection_floor if "current_inspection_floor" in Global else -1

	$Tower/FloorOptionsPanel.visible = true
	_disable_floor_option_buttons()
	$Tower/FloorOptionsPanel/FloorInfoLabel.text = "Select a floor"

	update_money_label()
	update_floor_ui()

	$Tower/FloorOptionsPanel/TrainingButton.pressed.connect(_on_training_button_pressed)
	$Tower/FloorOptionsPanel/WorkButton.pressed.connect(_on_work_button_pressed)
	$Tower/FloorOptionsPanel/InspectButton.pressed.connect(_on_inspection_button_pressed)
	$Tower/FloorOptionsPanel/ManageButton.pressed.connect(_on_manage_button_pressed)
	$Tower/FloorInspectionMode.visible = false

func _on_close_requested():
	queue_free()
	
func update_money_label():
	money_label.text = "Money: $" + str(Global.money)

func clear_children(container: Node) -> void:
	if container == null:
		print("❌ Tried to clear null container!")
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func update_floor_ui():
	for i in range(Global.building_floors.size()):
		var btn_name = "Floor%d" % (i + 1)
		var btn = floors_container.get_node_or_null(btn_name)
		if btn == null:
			push_error("⚠ Missing button: %s" % btn_name)
			continue

		var floor = Global.building_floors[i]

		match floor["state"]:
			Global.FloorState.LOCKED:
				btn.text = "🔒 Floor %d – Unlock $%d" % [i + 1, FLOOR_COST]
			Global.FloorState.AVAILABLE:
				btn.text = "Floor %d – Available to Inspect" % (i + 1)
			Global.FloorState.READY:
				btn.text = "Floor %d – Ready (%s)" % [i + 1, floor.get("purpose", "No Purpose")]
			Global.FloorState.ASSIGNED:
				btn.text = "Floor %d – %s Floor" % [i + 1, floor.get("purpose", "Unknown")]

		# Connect pressed signal safely
		if not btn.pressed.is_connected(_on_floor_button_pressed.bind(i)):
			btn.pressed.connect(_on_floor_button_pressed.bind(i))



func _on_floor_button_pressed(index):
	selected_floor_index = index
	var floor = Global.building_floors[index]

	match floor["state"]:
		Global.FloorState.LOCKED:
			if Global.money >= FLOOR_COST:
				Global.money -= FLOOR_COST
				floor["state"] = Global.FloorState.AVAILABLE
				Global.building_floors[index] = floor
				update_money_label()
				update_floor_ui()
				_disable_floor_option_buttons()
			else:
				print("Not enough money")
		Global.FloorState.AVAILABLE:
			show_floor_options(floor, index)
		Global.FloorState.READY:
			show_floor_assignment_options(floor, index)
		Global.FloorState.ASSIGNED:
			show_floor_assignment_options(floor, index)

func _disable_floor_option_buttons():
	$Tower/FloorOptionsPanel/TrainingButton.disabled = true
	$Tower/FloorOptionsPanel/WorkButton.disabled = true
	$Tower/FloorOptionsPanel/ManageButton.disabled = true
	$Tower/FloorOptionsPanel/InspectButton.disabled = true
	$Tower/FloorOptionsPanel/FloorInfoLabel.text = "Select a floor"

func show_floor_options(floor: Dictionary, index: int) -> void:
	$Tower/FloorOptionsPanel.visible = true
	$Tower/FloorOptionsPanel/FloorInfoLabel.text = "Floor %d - Current type: %s" % [index + 1, floor.get("purpose", "Empty")]
	$Tower/FloorOptionsPanel/TrainingButton.disabled = true
	$Tower/FloorOptionsPanel/WorkButton.disabled = true
	$Tower/FloorOptionsPanel/ManageButton.disabled = true
	$Tower/FloorOptionsPanel/InspectButton.disabled = (floor["state"] != Global.FloorState.AVAILABLE)

func show_floor_assignment_options(floor: Dictionary, index: int) -> void:
	$Tower/FloorOptionsPanel.visible = true
	$Tower/FloorOptionsPanel/FloorInfoLabel.text = "Floor %d - Current type: %s" % [index + 1, floor.get("purpose", "Empty")]
	$Tower/FloorOptionsPanel/TrainingButton.disabled = false
	$Tower/FloorOptionsPanel/WorkButton.disabled = false
	$Tower/FloorOptionsPanel/ManageButton.disabled = floor.get("purpose", "") == ""
	$Tower/FloorOptionsPanel/InspectButton.disabled = true

func _on_training_button_pressed():
	if selected_floor_index == -1:
		return
	var floor = Global.building_floors[selected_floor_index]
	floor["purpose"] = "Training Floor"
	Global.building_floors[selected_floor_index] = floor
	update_floor_ui()
	show_floor_assignment_options(floor, selected_floor_index)

	# Quest10: mark requirement 1 complete if Floor1
	if QuestManager.current_quest_id == 10 and selected_floor_index == 0:
		if not QuestManager.quests[10]["requirements"][1]["completed"]:
			QuestManager.complete_requirement(10, 1)


func _on_work_button_pressed():
	if selected_floor_index == -1:
		return
	var floor = Global.building_floors[selected_floor_index]
	floor["purpose"] = "Work Floor"
	Global.building_floors[selected_floor_index] = floor
	update_floor_ui()
	show_floor_assignment_options(floor, selected_floor_index)

	# Quest10: mark requirement 1 complete if Floor1
	if QuestManager.current_quest_id == 10 and selected_floor_index == 0:
		if not QuestManager.quests[10]["requirements"][1]["completed"]:
			QuestManager.complete_requirement(10, 1)


func assign_floor_purpose(floor_index: int, purpose: String) -> void:
	var floor = Global.building_floors[floor_index]
	floor["state"] = Global.FloorState.ASSIGNED
	floor["purpose"] = purpose

	if not floor.has("assigned_employee_indices"):
		floor["assigned_employee_indices"] = [null, null, null, null]

	Global.building_floors[floor_index] = floor

func _on_inspection_button_pressed():
	if selected_floor_index == -1:
		print("No floor selected!")
		return

	var floor = Global.building_floors[selected_floor_index]
	if floor["state"] != Global.FloorState.AVAILABLE:
		print("Floor not inspectable right now.")
		return

	# Replace the current scene instead of adding child
	var scene_path = "res://Scenes/Floors/Floor%d.tscn" % (selected_floor_index + 1)
	print("🔍 Loading floor scene:", scene_path)
	
	var floor_scene = load(scene_path)
	if floor_scene == null:
		push_error("Failed to load floor scene: %s" % scene_path)
		return
	get_tree().change_scene_to_packed(floor_scene)




func enter_inspection_mode():
	var scene_path = "res://Scenes/Floors/Floor%d.tscn" % (selected_floor_index + 1)
	print("Loading floor inspection:", scene_path)

	var floor_scene = load(scene_path)
	if floor_scene == null:
		push_error("Failed to load inspection scene: %s" % scene_path)
		return

	var instance = floor_scene.instantiate()

	# Pass the floor index if your floor scene expects it
	if instance.has_method("set_inspected_floor_index"):
		instance.set_inspected_floor_index(selected_floor_index)

	# Connect signal
	if instance.has_signal("inspection_complete"):
		instance.inspection_complete.connect(mark_floor_ready)

	# Add to scene tree
	get_tree().current_scene.add_child(instance)
	instance.position = Vector2.ZERO





func mark_floor_ready(floor_index: int):
	print("🔹 mark_floor_ready called with index:", floor_index)
	if floor_index < 0 or floor_index >= Global.building_floors.size():
		push_error("❌ Invalid floor index passed to mark_floor_ready: %d" % floor_index)
		return

	var floor = Global.building_floors[floor_index]
	print("🔹 Current state before marking READY:", floor["state"])
	floor["state"] = Global.FloorState.READY
	Global.building_floors[floor_index] = floor
	print("✅ Floor %d marked READY!" % (floor_index + 1))

	$Tower/FloorInspectionMode.visible = false
	floors_container.visible = true
	money_label.visible = true
	$Tower/FloorOptionsPanel.visible = true

	update_floor_ui()


func _on_manage_button_pressed():
	# Close this Floorplan window
	queue_free()

	# Load FloorManagement window
	var scene = load("res://Scenes/Maintenance/FloorManagement.tscn")
	if scene:
		var instance = scene.instantiate()
		# Add to the same container your other subpages live in
		var container = get_parent()  # usually $ContentContainer
		container.add_child(instance)
		# Center it if you want
		if instance is Window:
			instance.popup_centered_ratio(0.8)


func _on_floor_selected(floor_index):
	selected_floor_index = floor_index
	var floor_data = Global.building_floors[floor_index]

	$Tower/FloorOptionsPanel/ManageButton.visible = floor_data.unlocked

	# Hide ManagePanel initially when switching floors
	$ManagePanel.visible = false

func is_employee_available(emp_id):
	for floor in Global.building_floors:
		if "assigned_employee_indices" in floor and emp_id in floor["assigned_employee_indices"]:
			return false
	return true

func print_visibility(node: Node):
	print("%s visible: %s" % [node.name, str(node.visible)])
	for child in node.get_children():
		if child is Node:
			print_visibility(child)
