extends Window

@export var max_capacity: int = 6
@onready var floor_dropdown: OptionButton = $Control/ManagePanel/LeftPanel/FloorDropdown
@onready var floor_image: TextureRect = $Control/ManagePanel/LeftPanel/FloorImage
@onready var floor_name_label: Label = $Control/ManagePanel/LeftPanel/FloorNameLabel
@onready var power_bar: TextureProgressBar = $Control/ManagePanel/RightPanel/PowerBar

var EmployeeCard = preload("res://EmployeeCard.tscn")
var EmployeeAvatar = preload("res://EmployeeAvatar.tscn")

var current_floor_index: int = -1
var selected_slot_index: int = -1

# Simple local floors data
var floors = [
	{
		"name": "Floor 1",
		"image": preload("res://Assets/square-xxl.png"),
		"assigned_employee_indices": [null, null, null, null, null, null]
	},
	{
		"name": "Floor 2",
		"image": preload("res://Assets/square-xxl.png"),
		"assigned_employee_indices": [null, null, null, null, null, null]
	}
]


# Simple local employees data
var employees = [
	{"id": 1, "name": "Captain Whiskers", "avatar": preload("res://Assets/Avatars/emp1.png")},
	{"id": 2, "name": "Sir Purrsalot", "avatar": preload("res://Assets/Avatars/emp2.png")},
	{"id": 3, "name": "Whiskerstein", "avatar": preload("res://Assets/Avatars/emp3.png")},
	{"id": 4, "name": "Paws McGraw", "avatar": preload("res://Assets/Avatars/emp4.png")}
]

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)  # 60% of the screen
	print("Script attached to node: ", self.name)
	print("Children of current node: ", get_children().map(func(c): c.name))
	populate_floor_dropdown()
	floor_dropdown.item_selected.connect(_on_floor_dropdown_selected)
	if floor_dropdown.get_item_count() > 0:
		floor_dropdown.select(0)
		_on_floor_dropdown_selected(0)

	$Control/ScrollContainer.visible = false
	

	# Debug: print slot buttons info
	var slots_grid = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid
	print("Number of slot buttons:", slots_grid.get_child_count())
	for btn in slots_grid.get_children():
		print("Button:", btn.name, "visible:", btn.visible, "disabled:", btn.disabled, "mouse_filter:", btn.mouse_filter)

	# Connect slot buttons signals so clicks call _on_slot_pressed
	connect_slot_buttons()
	load_employee_slots()

func _on_close_requested():
	queue_free()
	
func update_power_bar():
	if current_floor_index == -1:
		power_bar.value = 0
		power_bar.max_value = max_capacity
		return

	var assigned = floors[current_floor_index]["assigned_employee_indices"]
	var assigned_count = 0
	for emp_id in assigned:
		if emp_id != null:
			assigned_count += 1

	power_bar.max_value = max_capacity
	power_bar.value = assigned_count


func populate_floor_dropdown():
	floor_dropdown.clear()
	for i in range(floors.size()):
		floor_dropdown.add_item(floors[i]["name"], i)  # pass i as metadata

func _on_floor_dropdown_selected(index: int) -> void:
	var metadata = floor_dropdown.get_item_metadata(index)
	if metadata == null:
		print("⚠️ Warning: No metadata for dropdown item ", index)
		return
	current_floor_index = metadata
	show_floor_info(floors[current_floor_index])
	load_employee_slots()

func get_slot_button(slot_index: int) -> Button:
	return $Control/ManagePanel/RightPanel/EmployeeSlotsGrid.get_child(slot_index)

func show_employee_list():
	print("Showing employee list...")
	var container = $Control/ScrollContainer/CardsContainer
	$Control/ScrollContainer.visible = true
	clear_children(container)

	for emp in employees:
		var card = EmployeeCard.instantiate()

		# card is the root Button, so connect signal directly on it
		card.connect("pressed", Callable(self, "_on_employee_card_pressed").bind(emp["id"], card))

		var avatar_node = card.get_node("Avatar")
		if avatar_node and avatar_node is TextureRect:
			avatar_node.texture = emp["avatar"]

		var name_label = card.get_node_or_null("NameLabel")
		if name_label:
			name_label.text = emp["name"]

		container.add_child(card)


func _on_employee_card_pressed(emp_id: int, card: Node):
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

	floors[current_floor_index]["assigned_employee_indices"][selected_slot_index] = emp_id
	print("Updated floor assignments: ", floors[current_floor_index]["assigned_employee_indices"])

	load_employee_slots()


func show_floor_info(floor_dict: Dictionary) -> void:
	floor_name_label.text = floor_dict.get("name", "Unknown Floor")
	var img = floor_dict.get("image", null)
	if img:
		floor_image.texture = img
	else:
		floor_image.texture = null
		
func connect_slot_buttons():
	var slots_grid = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid
	for i in range(slots_grid.get_child_count()):
		var btn = slots_grid.get_child(i)
		if btn.is_connected("pressed", Callable(self, "_on_slot_pressed")):
			btn.disconnect("pressed", Callable(self, "_on_slot_pressed"))
		btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))
		print("Connected slot button ", btn.name, " at index ", i)


func load_employee_slots():
	var assigned = floors[current_floor_index]["assigned_employee_indices"]
	print("Loading employee slots with assignments: ", assigned)
	var slots_grid = $Control/ManagePanel/RightPanel/EmployeeSlotsGrid
	var assigned_count = 0
	for i in range(max_capacity):
		var btn = slots_grid.get_child(i)
		var emp_id = assigned[i]
		print("Slot", i, "assigned employee id:", emp_id)
		if emp_id != null:
			assigned_count += 1
			var emp_index = employees.find(func(e): return e["id"] == emp_id)
			if emp_index != -1:
				var emp_data = employees[emp_index]
				print("Setting icon for slot", i, "to employee", emp_data["name"])
				btn.icon = emp_data["avatar"]
				btn.text = ""
		else:
			print("Clearing slot", i)
			btn.icon = null
			btn.text = "+"
	
	# Update the power bar here
	$Control/ManagePanel/RightPanel/PowerBar.value = assigned_count


func _on_slot_pressed(slot_index: int) -> void:
	print("Slot button pressed: ", slot_index)
	selected_slot_index = slot_index
	show_employee_list()


func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
