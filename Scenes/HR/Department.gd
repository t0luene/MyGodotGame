extends Popup

@export var max_capacity: int = 6
@onready var floor_image: TextureRect = $Control/ManagePanel/LeftPanel/FloorVisual
@onready var floor_name_label: Label = $Control/ManagePanel/LeftPanel/FloorInfo

var EmployeeCard = preload("res://EmployeeCard.tscn")
var EmployeeAvatar = preload("res://EmployeeAvatar.tscn")
var selected_slot_index: int = -1

# Local floors data (used only for UI info like images/role)
var floors = [
	{
		"name": "Floor 0",
		"image": preload("res://Assets/square-xxl.png"),
		"required_role": "HR"
	}
]

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)
	$Control/ScrollContainer.visible = false
	connect_slot_buttons()
	load_employee_slots()

func _on_close_requested():
	queue_free()

func get_slot_button(slot_index: int) -> Button:
	return $Control/ManagePanel/RightPanel/EmployeeSlotsGrid.get_child(slot_index)

func show_employee_list():
	print("Showing employee list...")
	var container = $Control/ScrollContainer/CardsContainer
	$Control/ScrollContainer.visible = true
	clear_children(container)

	# HR is floor 0 (index 1 in building_floors)
	var required_role = floors[0].get("required_role", null)
	var assigned_hr = Global.building_floors[1]["assigned_employee_indices"]

	for emp in Global.hired_employees:
		# Skip if already assigned to HR
		if emp.id in assigned_hr:
			continue

		# Skip if assigned to any other floor
		var assigned_elsewhere = false
		for i in range(Global.building_floors.size()):
			if i == 1: # skip HR floor
				continue
			if emp.id in Global.building_floors[i]["assigned_employee_indices"]:
				assigned_elsewhere = true
				break
		if assigned_elsewhere:
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
		if required_role == null or emp.role == required_role:
			card.modulate = Color(1,1,1)
		else:
			card.modulate = Color(0.7,0.7,0.7)

		container.add_child(card)



func _on_employee_card_pressed(emp_id: int, card: Node):
	if selected_slot_index < 0 or selected_slot_index >= max_capacity:
		print("⚠️ Invalid slot selected")
		return

	var required_role = floors[0].get("required_role", null)
	var emp = Global.hired_employees.filter(func(e): return e.id == emp_id)[0]

	# ✅ Prevent assigning wrong role
	if required_role != null and emp.role != required_role:
		print("⚠️ Employee role does not match requirement")
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

	# ✅ HR is at index 1 in building_floors (Floor 0 in game)
	Global.building_floors[1]["assigned_employee_indices"][selected_slot_index] = emp_id
	load_employee_slots()

	# ------------------------------
	# ✅ Mark HR assignment quest task complete
	# ------------------------------
	if QuestManager.current_quest_id == 6:  # Quest6
		QuestManager.complete_requirement(6, 4)  # requirement index 4 = "Assign HR"
		print("✅ HR task completed")


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
	if Global.building_floors.size() == 0:
		print("⚠️ No floors initialized yet")
		return

	# ✅ HR is floor index 1 (Floor0 in game)
	var assigned = Global.building_floors[1]["assigned_employee_indices"]
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
	var assigned = Global.building_floors[0]["assigned_employee_indices"]
	if assigned.all(func(id): return id != null):
		print("✅ All slots assigned — floor is complete!")
