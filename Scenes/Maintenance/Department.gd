extends Window

@export var max_capacity: int = 6
@onready var floor_image: TextureRect = $Control/ManagePanel/LeftPanel/FloorVisual
@onready var floor_name_label: Label = $Control/ManagePanel/LeftPanel/FloorInfo

var EmployeeCard = preload("res://EmployeeCard.tscn")
var EmployeeAvatar = preload("res://EmployeeAvatar.tscn")
var selected_slot_index: int = -1

# Local floor data (only for display in this page)
var floors = [
	{
		"name": "Floor -1",
		"image": preload("res://Assets/square-xxl.png"),
		"required_role": "Construction"
	}
]

# ✅ Maintenance = floor index 0
const FLOOR_INDEX := 0

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	$Control/ScrollContainer.visible = false
	connect_slot_buttons()
	load_employee_slots()
	show_floor_info(floors[0])

func _on_close_requested():
	queue_free()

func get_slot_button(slot_index: int) -> Button:
	return $Control/ManagePanel/RightPanel/EmployeeSlotsGrid.get_child(slot_index)

func show_employee_list():
	print("Showing employee list...")
	var container = $Control/ScrollContainer/CardsContainer
	$Control/ScrollContainer.visible = true
	clear_children(container)

	# Maintenance is floor -1
	var required_role = floors[-1].get("required_role", null)
	var assigned_indices = Global.building_floors[FLOOR_INDEX]["assigned_employee_indices"]

	for emp in Global.hired_employees:
		# Skip if employee is already assigned to **any floor**
		var is_assigned = false
		for floor_dict in Global.building_floors:
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

		# Gray out if role doesn't match
		if required_role != null and emp.role == required_role:
			card.modulate = Color(1,1,1)
		else:
			card.modulate = Color(0.7,0.7,0.7)

		container.add_child(card)

func _on_employee_card_pressed(emp_id: int, card: Node):
	if selected_slot_index < 0 or selected_slot_index >= max_capacity:
		print("⚠️ Invalid slot selected")
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

	# ✅ Assign employee to Maintenance floor (index 0)
	Global.building_floors[FLOOR_INDEX]["assigned_employee_indices"][selected_slot_index] = emp_id
	load_employee_slots()

	# ------------------------------
	# ✅ Mark Maintenance assignment quest task complete
	# ------------------------------
	if QuestManager.current_quest_id == 6:  # example: Quest6
		QuestManager.complete_requirement(6, 5)  
		print("✅ Maintenance task completed")

func show_floor_info(floor_dict: Dictionary) -> void:
	floor_name_label.text = floor_dict.get("name", "Unknown Floor")
	floor_image.texture = floor_dict.get("image", null)

func connect_slot_buttons():
	var slots_grid = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid
	for i in range(slots_grid.get_child_count()):
		var btn = slots_grid.get_child(i)
		if btn.is_connected("pressed", Callable(self, "_on_slot_pressed")):
			btn.disconnect("pressed", Callable(self, "_on_slot_pressed"))
		btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))

func load_employee_slots():
	if Global.building_floors.size() <= FLOOR_INDEX:
		print("⚠️ No floor at index ", FLOOR_INDEX)
		return

	var assigned = Global.building_floors[FLOOR_INDEX]["assigned_employee_indices"]
	var slots_grid = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid

	for i in range(max_capacity):
		if i >= assigned.size():
			assigned.append(null)
		var emp_id = assigned[i]
		var btn = slots_grid.get_child(i)

		if emp_id != null:
			var emp = Global.hired_employees.filter(func(e): return e.id == emp_id)
			if emp.size() > 0:
				var emp_data = emp[0]
				btn.icon = emp_data.avatar
				btn.text = ""
		else:
			btn.icon = null
			btn.text = "+"

func _on_slot_pressed(slot_index: int) -> void:
	selected_slot_index = slot_index
	show_employee_list()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func check_floor_completion():
	var assigned = Global.building_floors[FLOOR_INDEX]["assigned_employee_indices"]
	if assigned.all(func(id): return id != null):
		print("✅ All slots assigned — floor is complete!")
