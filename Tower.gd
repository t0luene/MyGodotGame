extends Control

const FLOOR_COST = 300
@export var inspected_floor_index: int = -1

var selected_floor_index = -1  # no floor selected initially
var selected_slot_index = -1
@onready var floors_container = $FloorsContainer
@onready var money_label = $MoneyLabel
var current_manage_index: int = -1
@export var max_capacity := 4
var floor_data: Dictionary = {}
var assigned_employees := []  # Assigned employee IDs per slot
var selected_slot := -1
func _ready():
	Global.ensure_floors_initialized(5)

	if Global.building_floors.size() > 0:
		var floor = Global.building_floors[0]
		floor["state"] = Global.FloorState.READY
		floor["purpose"] = "Work Floor"
		Global.building_floors[0] = floor

	update_money_label()
	update_floor_ui()

	inspected_floor_index = Global.current_inspection_floor if "current_inspection_floor" in Global else -1




	$ManagePanel/VBoxContainer/EmployeeList.visible = false

	$BackButton.pressed.connect(_on_back_button_pressed)
	$FloorOptionsPanel/TrainingButton.pressed.connect(_on_training_button_pressed)
	$FloorOptionsPanel/WorkButton.pressed.connect(_on_work_button_pressed)
	$FloorOptionsPanel/ManageButton.pressed.connect(_on_manage_button_pressed)

	$FloorOptionsPanel.visible = false
	$ManagePanel.visible = false
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
	clear_children(floors_container)

	for i in range(Global.building_floors.size()):
		var floor = Global.building_floors[i]
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		match floor["state"]:
			Global.FloorState.LOCKED:
				btn.text = "🔒 Floor %d – Unlock $%d" % [i + 1, FLOOR_COST]
			Global.FloorState.AVAILABLE:
				btn.text = "Floor %d – Available to Inspect" % (i + 1)
			Global.FloorState.READY:
				btn.text = "Floor %d – Ready (%s)" % [i + 1, floor.get("purpose", "No Purpose")]
			Global.FloorState.ASSIGNED:
				btn.text = "Floor %d – %s Floor" % [i + 1, floor.get("purpose", "Unknown")]

		btn.pressed.connect(_on_floor_button_pressed.bind(i))
		floors_container.add_child(btn)


func _on_floor_button_pressed(index):
	var floor = Global.building_floors[index]

	match floor["state"]:
		Global.FloorState.LOCKED:
			if Global.money >= FLOOR_COST:
				Global.money -= FLOOR_COST
				floor["state"] = Global.FloorState.AVAILABLE
				Global.building_floors[index] = floor
				update_money_label()
				update_floor_ui()
			else:
				print("Not enough money")
		Global.FloorState.AVAILABLE:
			selected_floor_index = index
			show_floor_options(floor, index)
		Global.FloorState.READY:
			selected_floor_index = index
			show_floor_assignment_options(floor, index)
		Global.FloorState.ASSIGNED:
			selected_floor_index = index
			show_manage_panel(floor, index)


func show_floor_options(floor: Dictionary, index: int) -> void:
	$FloorOptionsPanel.visible = true
	$FloorOptionsPanel/FloorInfoLabel.text = "Floor %d - Current type: %s" % [index + 1, floor.get("purpose", "Empty")]

	# For AVAILABLE floors, hide purpose buttons (inspection only)
	$FloorOptionsPanel/TrainingButton.visible = false
	$FloorOptionsPanel/WorkButton.visible = false
	$FloorOptionsPanel/ManageButton.visible = false


func show_floor_assignment_options(floor: Dictionary, index: int) -> void:
	$FloorOptionsPanel.visible = true
	$FloorOptionsPanel/FloorInfoLabel.text = "Floor %d - Current type: %s" % [index + 1, floor.get("purpose", "Empty")]

	$FloorOptionsPanel/TrainingButton.visible = true
	$FloorOptionsPanel/WorkButton.visible = true
# Show the manage button if the floor already has a purpose
	$FloorOptionsPanel/ManageButton.visible = floor.get("purpose", "") != ""

func show_manage_panel(floor: Dictionary, index: int) -> void:
	current_manage_index = index
	$ManagePanel.visible = true

	var purpose = floor.get("purpose", "Unknown")
	$ManagePanel/VBoxContainer/Label.text = "Manage Floor %d – %s" % [index + 1, purpose]

	var slots_container = $ManagePanel/VBoxContainer/EmployeeSlotsGrid
	clear_children(slots_container)

	var capacity = floor.get("capacity", max_capacity)
	var assigned = floor.get("assigned_employee_indices", [])

	# Ensure assigned list matches capacity size
	while assigned.size() < capacity:
		assigned.append(null)
	floor["assigned_employee_indices"] = assigned
	Global.building_floors[index] = floor

	for slot_i in range(capacity):
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(100, 100)

		if assigned[slot_i] != null:
			var emp_id = assigned[slot_i]
			var emp = Global.get_employee_by_id(emp_id)
			btn.text = emp.name if emp != null else "Unknown"
			btn.modulate = Color(0.8, 0.8, 0.8)
		else:
			btn.text = "+"
			btn.modulate = Color(0.6, 0.6, 0.6)

		# Disconnect previous pressed signals to avoid duplicates
		var callable = Callable(self, "_on_slot_pressed").bind(slot_i)

		if btn.is_connected("pressed", callable):
			btn.disconnect("pressed", callable)

		btn.connect("pressed", callable)

		slots_container.add_child(btn)

	var num_assigned = assigned.filter(func(i): return i != null).size()
	var power_bar = $ManagePanel/VBoxContainer/PowerBar
	power_bar.max_value = capacity
	power_bar.value = num_assigned

	$FloorOptionsPanel.visible = false



func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Game.tscn")


func _on_training_button_pressed():
	if selected_floor_index == -1:
		return
	var floor = Global.building_floors[selected_floor_index]
	floor["purpose"] = "Training Floor"
	Global.building_floors[selected_floor_index] = floor
	update_floor_ui()
	$FloorOptionsPanel.visible = false


func _on_work_button_pressed():
	if selected_floor_index == -1:
		return
	var floor = Global.building_floors[selected_floor_index]
	floor["purpose"] = "Work Floor"
	Global.building_floors[selected_floor_index] = floor
	update_floor_ui()
	$FloorOptionsPanel.visible = false


func _on_assign_purpose_pressed(purpose: String):
	if selected_floor_index == -1:
		return
	assign_floor_purpose(selected_floor_index, purpose)
	update_floor_ui()
	$FloorOptionsPanel.visible = false


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
	var scene_path = "res://Floor%dInspection.tscn" % (selected_floor_index + 1)
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
	$ManagePanel.visible = false

	# Hide other Building UI parts for clean inspection mode
	floors_container.visible = false
	money_label.visible = false
	$BackButton.visible = false



func mark_floor_ready(floor_index: int):
	var floor = Global.building_floors[floor_index]
	floor["state"] = Global.FloorState.READY
	Global.building_floors[floor_index] = floor
	print("✅ Floor %d marked READY!" % (floor_index + 1))

	# Hide inspection UI
	$FloorInspectionMode.visible = false

	# Show Building UI parts again
	floors_container.visible = false

	money_label.visible = false
	$BackButton.visible = true

	# Refresh UI to reflect changes
	update_floor_ui()









func _on_assign_employee_to_floor(floor_index: int, slot_index: int):
	print("Assign button pressed for floor %d slot %d" % [floor_index, slot_index])

	selected_floor_index = floor_index
	selected_slot_index = slot_index
	$ManagePanel/VBoxContainer/EmployeeList.visible = true
	print("Employee list visible:", $ManagePanel/VBoxContainer/EmployeeList.visible)

	_populate_employee_list()



func _on_floor_selected(floor_index):
	selected_floor_index = floor_index
	var floor_data = Global.building_floors[floor_index]

	$FloorOptionsPanel/ManageButton.visible = floor_data.unlocked

	# Hide ManagePanel initially when switching floors
	$ManagePanel.visible = false

func _on_manage_button_pressed():
	print("Manage button clicked!")
	var floor_data = Global.building_floors[selected_floor_index]
	show_manage_panel(floor_data, selected_floor_index)
	
	
func load_manage_panel_data():
	var assigned = Global.building_floors[selected_floor_index].get("assigned_employee_indices", [null, null, null, null])

	for i in range(4):
		var btn = $ManagePanel/VBoxContainer/GridContainer.get_child(i)
		if assigned[i] != null:
			var emp = Global.get_employee_by_id(assigned[i])  # Assuming you have such a helper function
			btn.text = emp.name
		else:
			btn.text = "Assign"
		btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(i), CONNECT_DEFERRED)






	
func _on_slot_pressed(slot_index: int) -> void:
	selected_slot = slot_index
	selected_slot_index = slot_index
	print("Slot pressed:", slot_index)
	_show_employee_list()



func _on_employee_selected(emp_id: int) -> void:
	print("Employee selected signal received for emp_id:", emp_id)

	if selected_floor_index == -1 or selected_slot_index == -1:
		return
	
	var floor = Global.building_floors[selected_floor_index]
	if not floor.has("assigned_employee_indices"):
		floor["assigned_employee_indices"] = []
	
	while floor["assigned_employee_indices"].size() <= selected_slot_index:
		floor["assigned_employee_indices"].append(null)
	
	floor["assigned_employee_indices"][selected_slot_index] = emp_id
	
	# Mark employee busy, adjust if your global method differs
	Global.assign_employee_to_mission(emp_id)
	
	Global.building_floors[selected_floor_index] = floor
	
	update_floor_ui()
	show_manage_panel(floor, selected_floor_index)
	
	selected_floor_index = -1
	selected_slot_index = -1
	$ManagePanel/VBoxContainer/EmployeeList.visible = false



func is_employee_available(emp_id):
	for floor in Global.building_floors:
		if "assigned_employee_indices" in floor and emp_id in floor["assigned_employee_indices"]:
			return false
	return true


func _on_employee_list_item_selected(index):
	if selected_floor_index == -1 or selected_slot_index == -1:
		return
	
	var emp_name = $ManagePanel/VBoxContainer/EmployeeList.get_item_text(index)
	# Find the employee id by name or use index directly
	var emp_id = Global.get_employee_id_by_name(emp_name)
	
	var floor = Global.building_floors[selected_floor_index]
	if not floor.has("assigned_employee_indices"):
		floor["assigned_employee_indices"] = []
	
	# Make sure the list has enough slots
	while floor["assigned_employee_indices"].size() <= selected_slot_index:
		floor["assigned_employee_indices"].append(null)
	
	floor["assigned_employee_indices"][selected_slot_index] = emp_id
	
	Global.assign_employee_to_mission(emp_id)
	Global.building_floors[selected_floor_index] = floor
	
	# Refresh UI
	update_floor_ui()
	show_manage_panel(floor, selected_floor_index)
	
	# Reset selection and hide list
	selected_floor_index = -1
	selected_slot_index = -1
	$ManagePanel/VBoxContainer/EmployeeList.visible = false


func get_available_employees() -> Array:
	var available := []
	for employee in Global.hired_employees:
		if not employee.get("is_busy", false):
			available.append(employee)
	return available



func _on_AssignButton_pressed():
	var available = get_available_employees()
	if available.empty():
		print("No employees available!")
		return

	# Assign first available employee for test
	var employee = available[0]
	var emp_index = Global.hired_employees.find(employee)

	if emp_index == -1:
		print("❌ Employee not found in hired_employees!")
		return

	Global.hired_employees[emp_index]["is_busy"] = true

	var floor = Global.building_floors[current_manage_index]
	if not floor.has("assigned_employee_indices") or floor["assigned_employee_indices"] == null:
		floor["assigned_employee_indices"] = []

	# Assign employee to first empty slot
	var assigned = floor["assigned_employee_indices"]
	var assigned_index = assigned.find(null)
	if assigned_index == -1:
		assigned.append(emp_index)
	else:
		assigned[assigned_index] = emp_index

	floor["assigned_employee_indices"] = assigned
	Global.building_floors[current_manage_index] = floor

	show_manage_panel(floor, current_manage_index)

func update_power_bar():
	var assigned = Global.building_floors[current_manage_index]["assigned_employee_indices"]
	var power_bar = $ManagePanel/VBoxContainer/PowerBar
	power_bar.value = assigned.size()

func setup_floor(floor: Dictionary):
	floor_data = floor
	assigned_employees = floor.get("assigned_employee_indices", [])
	_update_power_bar()
	_update_floor_visual()
	_update_employee_slots()

func _update_power_bar():
	var num_assigned = assigned_employees.filter(func(eid): return eid != null).size()
	$ManagePanel/VBoxContainer/PowerBar.max_value = max_capacity
	$ManagePanel/VBoxContainer/PowerBar.value = num_assigned

func _update_floor_visual():
	# Placeholder floor image - replace with your own texture path
	$ManagePanel/VBoxContainer/FloorVisual.texture = preload("res://Assets/floor1.png")

func _update_employee_slots():
	for i in range(max_capacity):
		var slot_btn = $ManagePanel/VBoxContainer/EmployeeSlotsGrid.get_child(i)
		if i < assigned_employees.size() and assigned_employees[i] != null:
			var emp_id = assigned_employees[i]
			var emp = Global.get_employee_by_id(emp_id)
			if emp:
				slot_btn.text = emp.name
			else:
				slot_btn.text = "Unknown"
		else:
			slot_btn.text = "+"



func _show_employee_list():
	print("Showing employee list")

	$ManagePanel/VBoxContainer/EmployeeList.visible = true
	print("EmployeeList visible now:", $ManagePanel/VBoxContainer/EmployeeList.visible)

	_populate_employee_list()

func _populate_employee_list():
	print("Populating employee list...")

	var container = $ManagePanel/VBoxContainer/EmployeeList/ScrollContainer/EmployeeListContainer
	if container == null:
		print("❌ EmployeeListContainer not found!")
		return

	clear_children(container)

	# TEST LABEL
	var label = Label.new()
	label.text = "✅ TEST EMPLOYEE"
	container.add_child(label)

	var available = _get_available_employees()
	print("Available employees: ", available)

	var card_scene := preload("res://EmployeeCard.tscn")

	for emp in available:
		print("Adding employee: ", emp.get("name", "Unknown"))

		var emp_card = card_scene.instantiate()
		emp_card.set_employee_data(emp)

		emp_card.custom_minimum_size = Vector2(300, 80)

		emp_card.employee_selected.connect(Callable(self, "_on_employee_selected"))

		container.add_child(emp_card)



func _get_available_employees() -> Array:
	# TEST ONLY: Return 2 fake employees so the list always shows something
	return [
		{"id": 1, "name": "Mario", "is_busy": false},
		{"id": 2, "name": "Luigi", "is_busy": false}
	]


func print_visibility(node: Node):
	print("%s visible: %s" % [node.name, str(node.visible)])
	for child in node.get_children():
		if child is Node:
			print_visibility(child)
