extends Window

const FLOOR_UNLOCK_COST = 5      # Cheap unlock (just access)
const FLOOR_ASSIGN_COST = 300    # Expensive setup (when assigning purpose)

@export var inspected_floor_index: int = -1
@onready var floors_container = $Tower/FloorsContainer
@onready var money_label = $Tower/MoneyLabel
@export var max_capacity := 4
@onready var building_container = $Tower/BuildingContainer
@export var room_scene: PackedScene = preload("res://Scenes/Shared/RoomSquare.tscn")
@onready var travel_button = $Tower/FloorOptionsPanel/TravelButton
@export var building_manage_mode := false  # default false, true for whole-building Manage


var selected_floor_index = -1  # no floor selected initially
var current_manage_index: int = -1
var selected_slot := -1
var current_floor: String = ""



func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	Global.ensure_building_floors_initialized()

	travel_button.pressed.connect(_on_travel_button_pressed)

	# Make TravelButton always visible and enabled
	travel_button.visible = true
	travel_button.disabled = false

	# Initialize selection variables
	selected_floor_index = -1
	current_manage_index = -1
	selected_slot = -1
	inspected_floor_index = Global.current_inspection_floor if "current_inspection_floor" in Global else -1

	# Show FloorOptionsPanel and enable Manage button by default
	$Tower/FloorOptionsPanel.visible = true
	$Tower/FloorOptionsPanel/ManageButton.disabled = false  # <-- ENABLE Manage immediately
	$Tower/FloorOptionsPanel/FloorInfoLabel.text = "Manage Building"

	# Other buttons start disabled
	$Tower/FloorOptionsPanel/TrainingButton.disabled = true
	$Tower/FloorOptionsPanel/WorkButton.disabled = true
	$Tower/FloorOptionsPanel/InspectButton.disabled = true

	update_money_label()
	update_floor_ui()

	# Connect signals
	$Tower/FloorOptionsPanel/TrainingButton.pressed.connect(_on_training_button_pressed)
	$Tower/FloorOptionsPanel/WorkButton.pressed.connect(_on_work_button_pressed)
	$Tower/FloorOptionsPanel/InspectButton.pressed.connect(_on_inspection_button_pressed)
	$Tower/FloorOptionsPanel/ManageButton.pressed.connect(_on_manage_button_pressed)

	$Tower/FloorInspectionMode.visible = false


#-----TRAVEL-----

func _on_travel_button_pressed() -> void:
	if selected_floor_index < 0 or selected_floor_index >= Global.building_floors.size():
		print("Travel button pressed -> invalid floor_index:", selected_floor_index)
		return

	var floor = Global.building_floors[selected_floor_index]

	if floor["state"] != Global.FloorState.READY and floor["state"] != Global.FloorState.ASSIGNED:
		print("Travel button pressed -> floor not ready:", selected_floor_index)
		return


	print("Travel button pressed -> traveling to floor_index:", selected_floor_index)

	# Use your existing hallway system
	var scene_path = "res://Scenes/Shared/Hallway.tscn"
	var hallway_scene = load(scene_path)
	if hallway_scene == null:
		push_error("❌ Failed to load hallway scene for travel: %s" % scene_path)
		return

	# Store the floor index globally so the hallway knows which floor to display
	Global.current_inspection_floor = selected_floor_index

	# Replace current scene
	get_tree().change_scene_to_packed(hallway_scene)




# -------------------------------
# STEP 1: Populate building
# -------------------------------
func show_floor_editor(floor_index: int):
	var floor = Global.building_floors[floor_index]
	if floor["state"] != Global.FloorState.READY:
		print("Floor not ready for editing!")
		return

	# Clear previous editor
	clear_children($FloorPlanContainer)

	# Instance FloorPlanEditor
	var editor = preload("res://Scenes/Shared/FloorPlanEditor.tscn").instantiate()
	$FloorPlanContainer.add_child(editor)
	$FloorPlanContainer.visible = true

	# Setup editor with floor data and room_scene
	editor.setup(floor_index, floor)
	editor.room_scene = room_scene  # optional, if you need to instance rooms later

#-------------------------------------------

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
				btn.text = "🔒 Floor %d – Unlock $%d" % [i + 1, FLOOR_UNLOCK_COST]

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
			if Global.money >= FLOOR_UNLOCK_COST:
				Global.set_money(Global.money - FLOOR_UNLOCK_COST)
				floor["state"] = Global.FloorState.AVAILABLE
				Global.building_floors[index] = floor
				update_floor_ui()
				_disable_floor_option_buttons()
				print("✅ Floor %d unlocked for $%d" % [index + 1, FLOOR_UNLOCK_COST])
			else:
				print("❌ Not enough money to unlock floor %d" % (index + 1))
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

	# Enable Manage only for READY floors
	if floor["state"] == Global.FloorState.READY or floor["state"] == Global.FloorState.ASSIGNED:
		$Tower/FloorOptionsPanel/ManageButton.disabled = false
	else:
		$Tower/FloorOptionsPanel/ManageButton.disabled = true

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

	var scene_path: String

	# Tutorial floor logic
	if selected_floor_index == 0:  # Floor1 tutorial
		scene_path = "res://Scenes/Floors/Floor1.tscn"  # custom tutorial hallway
		Global.current_floor_scene = "floor1_tutorial"
	else:  # Floor2 onward → dynamic hallway
		scene_path = "res://Scenes/Shared/Hallway.tscn"
		Global.current_floor_scene = "floor%d" % (selected_floor_index + 1)

	print("🔍 Loading floor scene:", scene_path)
	var floor_scene = load(scene_path)
	if floor_scene == null:
		push_error("❌ Failed to load floor scene: %s" % scene_path)
		return

	Global.current_inspection_floor = selected_floor_index

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

	# Set floor state to READY
	Global.set_floor_state(floor_index, Global.FloorState.READY)

	# Initialize rooms array if it doesn't exist
	if not floor.has("rooms") or !(floor["rooms"] is Array):
		floor["rooms"] = []

	# Assign persistent unique IDs for this floor and its rooms
	if not floor.has("floor_id"):
		floor["floor_id"] = "floor_%d" % floor_index

	if not floor.has("room_ids") or !(floor["room_ids"] is Array):
		floor["room_ids"] = []
		for room_dict in floor["rooms"]:
			if room_dict.has("scene"):
				var unique_id = "%s_%s" % [floor["floor_id"], room_dict["scene"].get_file().get_basename()]
				floor["room_ids"].append(unique_id)

	Global.building_floors[floor_index] = floor

	print("✅ Floor %d marked READY with floor_id: %s and room_ids: %s" %
		  [floor_index + 1, floor["floor_id"], floor["room_ids"]])

	# Hide inspection mode UI
	$Tower/FloorInspectionMode.visible = false
	floors_container.visible = true
	money_label.visible = true
	$Tower/FloorOptionsPanel.visible = true

	# Update UI buttons and labels
	update_floor_ui()
	show_floor_assignment_options(floor, floor_index)


 

func _on_manage_button_pressed():
	var editor = preload("res://Scenes/Shared/FloorPlanEditor.tscn").instantiate()
	clear_children($FloorPlanContainer)
	$FloorPlanContainer.add_child(editor)
	$FloorPlanContainer.visible = true
	editor.setup(-1, Global.building_floors)  
	editor.room_scene = room_scene



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
# Called whenever a floor's state changes
func _on_floor_state_changed(floor_index: int):
	print("🌐 Floorplan: floor_state_changed received for floor", floor_index)
	if floor_index < 0 or floor_index >= Global.building_floors.size():
		push_error("❌ Invalid floor_index received in _on_floor_state_changed: %d" % floor_index)
		return
	_refresh_floor_buttons()

# Refresh the UI for all floors based on Global.building_floors
func _refresh_floor_buttons():
	print("🌐 Floorplan: refreshing all floor buttons")
	for i in range(Global.building_floors.size()):
		var floor = Global.building_floors[i]
		var button_name = "FloorButton%d" % (i + 1)
		var btn = $FloorButtons.get_node_or_null(button_name)
		if not btn:
			print("⚠ Floorplan: button not found:", button_name)
			continue

		match floor["state"]:
			Global.FloorState.LOCKED:
				btn.disabled = true
				btn.text = "Locked"
			Global.FloorState.AVAILABLE:
				btn.disabled = false
				btn.text = "Inspect"
			Global.FloorState.READY:
				btn.disabled = false
				btn.text = "Ready"
			Global.FloorState.ASSIGNED:
				btn.disabled = false
				btn.text = "Assigned"

		print("  🔹 Button", button_name, "set to", btn.text, "(state =", floor["state"], ")")
