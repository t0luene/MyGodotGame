extends Popup

@export var max_capacity: int = 6
@onready var floor_dropdown: OptionButton = $Control/ManagePanel/LeftPanel/FloorDropdown
@onready var slots_grid: GridContainer = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid

var current_floor_index: int = -1
var selected_slot_index: int = -1

var EmployeeCard = preload("res://EmployeeCard.tscn")
var EmployeeAvatar = preload("res://EmployeeAvatar.tscn")


func _ready():
		# Flag Quest10 requirement 3 as done immediately
	if QuestManager.current_quest_id == 10:
		QuestManager.open_floor_management()
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	populate_floor_dropdown()
	floor_dropdown.item_selected.connect(_on_floor_dropdown_selected)
	connect_slot_buttons()
	load_employee_slots()

func _on_close_requested():
	queue_free()
	
func populate_floor_dropdown():
	floor_dropdown.clear()

	Global.ensure_building_floors_initialized()

	# Only loop Floor1–Floor13
	for i in range(1, 14):
		if i >= Global.building_floors.size():
			continue

		var floor_dict = Global.building_floors[i]
		if not floor_dict.has("label"):
			continue

		floor_dropdown.add_item(floor_dict["label"])
		floor_dropdown.set_item_metadata(floor_dropdown.get_item_count() - 1, i)
		var is_ready = floor_dict.get("state", Global.FloorState.LOCKED) == Global.FloorState.READY
		floor_dropdown.set_item_disabled(floor_dropdown.get_item_count() - 1, not is_ready)
		print("Added floor:", floor_dict["label"], "dropdown index:", floor_dropdown.get_item_count() - 1, "READY?", is_ready)

	# Auto-select first READY floor
	for i in range(floor_dropdown.get_item_count()):
		if not floor_dropdown.is_item_disabled(i):
			floor_dropdown.select(i)
			_on_floor_dropdown_selected(i)
			break


func _on_floor_dropdown_selected(index: int):
	var meta = floor_dropdown.get_item_metadata(index)
	if meta == null:
		current_floor_index = -1
		print("⚠️ No floor selected, dropdown index:", index, "metadata:", meta)
	else:
		current_floor_index = int(meta)
		print("🔹 Dropdown selection triggered, index:", index, "metadata:", meta)
	load_employee_slots()


func connect_slot_buttons():
	var slots_grid = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid
	for i in range(slots_grid.get_child_count()):
		var btn = slots_grid.get_child(i)
		if btn.is_connected("pressed", Callable(self, "_on_slot_pressed")):
			btn.disconnect("pressed", Callable(self, "_on_slot_pressed"))
		btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))

func load_employee_slots():
	for i in range(slots_grid.get_child_count()):
		var btn = slots_grid.get_child(i)
		btn.icon = null
		btn.text = "+"

	if current_floor_index == -1:
		print("⚠️ Cannot load slots: no floor selected")
		return

	var assigned = Global.building_floors[current_floor_index]["assigned_employee_indices"]

	# Expand list if smaller than capacity
	while assigned.size() < max_capacity:
		assigned.append(null)

	for i in range(max_capacity):
		var emp_id = assigned[i]
		var btn = slots_grid.get_child(i)

		if emp_id != null:
			var emp = Global.hired_employees.filter(func(e): return e.id == emp_id)
			if emp.size() > 0:
				btn.icon = emp[0].avatar
				btn.text = ""
			print("Loaded slot", i, "with employee id:", emp_id)
		else:
			print("Loaded slot", i, "empty")

	print("Finished loading slots for floor", current_floor_index)



func _on_employee_card_pressed(emp_id: int, card: Node):
	if selected_slot_index < 0 or selected_slot_index >= max_capacity:
		print("⚠️ Invalid slot selected")
		return
	if current_floor_index == -1:
		print("⚠️ No floor selected")
		return

	$Control/ScrollContainer.visible = false

	var slot_btn = get_slot_button(selected_slot_index)
	if slot_btn:
		clear_children(slot_btn)
		var avatar = TextureRect.new()
		avatar.texture = card.get_node("Avatar").texture
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar.expand = true
		avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_btn.add_child(avatar)
		slot_btn.text = ""

	# ✅ Assign employee to the **currently selected floor**
	var assigned = Global.building_floors[current_floor_index]["assigned_employee_indices"]
	if selected_slot_index >= assigned.size():
		# pad the array if it's smaller than max_capacity
		while assigned.size() <= selected_slot_index:
			assigned.append(null)
	assigned[selected_slot_index] = emp_id

	print("Assigned employee id:", emp_id, "to floor:", current_floor_index, "slot:", selected_slot_index)

	# Reload to refresh UI properly
	load_employee_slots()


func get_slot_button(slot_index: int) -> Button:
	return $Control/ManagePanel/RightPanel/EmployeeSlotsGrid.get_child(slot_index)

func show_employee_list():
	print("Showing employee list...")
	var container = $Control/ScrollContainer/CardsContainer
	$Control/ScrollContainer.visible = true
	clear_children(container)

	var assigned_indices = Global.building_floors[current_floor_index]["assigned_employee_indices"]

	for emp in Global.hired_employees:
		# Skip if employee is already assigned to **any floor 1–13**
		var is_assigned = false
		for i in range(1, 14):
			if i >= Global.building_floors.size():
				continue
			var floor_dict = Global.building_floors[i]
			if not floor_dict.has("assigned_employee_indices"):
				continue
			if emp.id in floor_dict["assigned_employee_indices"]:
				is_assigned = true
				break
		if is_assigned:
			continue

		var card = EmployeeCard.instantiate()
		card.connect("pressed", Callable(self, "_on_employee_card_pressed").bind(emp.id, card))

		# Fill UI
		card.get_node("ProficiencyLabel").text = str(emp.proficiency)
		card.get_node("CostLabel").text = str(emp.cost)
		card.get_node("Avatar").texture = emp.avatar
		card.get_node("NameLabel").text = emp.name
		card.get_node("RoleLabel").text = emp.role

		container.add_child(card)


func _on_slot_pressed(slot_index: int) -> void:
	selected_slot_index = slot_index
	show_employee_list()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
