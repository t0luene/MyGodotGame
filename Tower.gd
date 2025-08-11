extends Control

const FLOOR_COST = 300
@export var inspected_floor_index: int = -1
var selected_floor_index = -1  # no floor selected initially
@onready var floors_container = $FloorsContainer
@onready var money_label = $MoneyLabel
var current_manage_index: int = -1
@export var max_capacity := 4

var selected_slot := -1

func _ready():
	Global.ensure_floors_initialized(13)  # Now matches Floor1..Floor13

	$FloorOptionsPanel.visible = true
	_disable_floor_option_buttons()
	$FloorOptionsPanel/FloorInfoLabel.text = "Select a floor"

	if Global.building_floors.size() > 0:
		var floor = Global.building_floors[0]
		floor["state"] = Global.FloorState.READY
		floor["purpose"] = "Work Floor"
		Global.building_floors[0] = floor

	update_money_label()
	update_floor_ui()

	inspected_floor_index = Global.current_inspection_floor if "current_inspection_floor" in Global else -1

	$FloorOptionsPanel/TrainingButton.pressed.connect(_on_training_button_pressed)
	$FloorOptionsPanel/WorkButton.pressed.connect(_on_work_button_pressed)
	$FloorOptionsPanel/InspectButton.pressed.connect(_on_inspection_button_pressed)
	$FloorOptionsPanel/ManageButton.pressed.connect(_on_manage_button_pressed)

	$FloorInspectionMode.visible = false

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

		# Avoid multiple connections
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
	$FloorOptionsPanel/TrainingButton.disabled = true
	$FloorOptionsPanel/WorkButton.disabled = true
	$FloorOptionsPanel/ManageButton.disabled = true
	$FloorOptionsPanel/InspectButton.disabled = true
	$FloorOptionsPanel/FloorInfoLabel.text = "Select a floor"

func show_floor_options(floor: Dictionary, index: int) -> void:
	$FloorOptionsPanel.visible = true
	$FloorOptionsPanel/FloorInfoLabel.text = "Floor %d - Current type: %s" % [index + 1, floor.get("purpose", "Empty")]

	# AVAILABLE floors can only inspect, no assignment or manage yet
	$FloorOptionsPanel/TrainingButton.disabled = true
	$FloorOptionsPanel/WorkButton.disabled = true
	$FloorOptionsPanel/ManageButton.disabled = true

	# Enable Inspect button only if floor is AVAILABLE
	$FloorOptionsPanel/InspectButton.disabled = (floor["state"] != Global.FloorState.AVAILABLE)

func show_floor_assignment_options(floor: Dictionary, index: int) -> void:
	$FloorOptionsPanel.visible = true
	$FloorOptionsPanel/FloorInfoLabel.text = "Floor %d - Current type: %s" % [index + 1, floor.get("purpose", "Empty")]

	# Enable assignment buttons
	$FloorOptionsPanel/TrainingButton.disabled = false
	$FloorOptionsPanel/WorkButton.disabled = false

	# Manage button enabled only if floor has a purpose assigned
	$FloorOptionsPanel/ManageButton.disabled = floor.get("purpose", "") == ""

	# Disable Inspect button here — can't inspect assigned floors
	$FloorOptionsPanel/InspectButton.disabled = true

func _on_training_button_pressed():
	if selected_floor_index == -1:
		return
	var floor = Global.building_floors[selected_floor_index]
	floor["purpose"] = "Training Floor"
	Global.building_floors[selected_floor_index] = floor
	update_floor_ui()
	# Keep panel visible and floor selected with updated info
	show_floor_assignment_options(floor, selected_floor_index)

func _on_work_button_pressed():
	if selected_floor_index == -1:
		return
	var floor = Global.building_floors[selected_floor_index]
	floor["purpose"] = "Work Floor"
	Global.building_floors[selected_floor_index] = floor
	update_floor_ui()
	# Keep panel visible and floor selected with updated info
	show_floor_assignment_options(floor, selected_floor_index)

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
	enter_inspection_mode()

func enter_inspection_mode():
	var scene_path = "res://Floor1Inspection.tscn"
	var floor_scene = load(scene_path)
	if floor_scene == null:
		print("❌ Failed to load inspection scene:", scene_path)
		return

	var instance = floor_scene.instantiate()
	instance.inspected_floor_index = selected_floor_index

	if instance.has_signal("inspection_complete"):
		instance.inspection_complete.connect(mark_floor_ready)

	var container = $FloorInspectionMode
	clear_children(container)
	container.add_child(instance)
	instance.position = Vector2.ZERO
	container.visible = true

	$FloorOptionsPanel.visible = false
	floors_container.visible = false      # Hide floor buttons container
	money_label.visible = false           # Hide money display
	# Also hide other UI elements if needed, e.g.:
	# $SomeOtherUIPanel.visible = false


func mark_floor_ready(floor_index: int):
	var floor = Global.building_floors[floor_index]
	floor["state"] = Global.FloorState.READY
	Global.building_floors[floor_index] = floor
	print("✅ Floor %d marked READY!" % (floor_index + 1))

	$FloorInspectionMode.visible = false

	# Show UI parts back again
	floors_container.visible = true
	money_label.visible = true
	$FloorOptionsPanel.visible = true  # Show options panel again if desired

	update_floor_ui()


func _on_manage_button_pressed():
	get_tree().change_scene("res://BuildingManagement.tscn")

func _on_floor_selected(floor_index):
	selected_floor_index = floor_index
	var floor_data = Global.building_floors[floor_index]

	$FloorOptionsPanel/ManageButton.visible = floor_data.unlocked

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
