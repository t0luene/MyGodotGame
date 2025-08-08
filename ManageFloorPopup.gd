extends Panel

var assigned_employees = [null, null, null, null]  # Store assigned employee IDs or objects
var current_slot = -1

func _ready():
	$employee_list.visible = false
	for i in range(4):
		var slot_btn = get_node("VBoxContainer/HBoxContainer/slot_%d" % (i + 1))
		slot_btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))
	$employee_list.connect("item_selected", Callable(self, "_on_employee_selected"))
	$Close.connect("pressed", Callable(self, "_on_close_pressed"))



func _on_slot_pressed(slot_index):
	current_slot = slot_index
	populate_employee_list()
	$employee_list.visible = true
	$employee_list.grab_focus()

func populate_employee_list():
	$employee_list.clear()
	# Assuming Global.employees is a list of employee dicts with 'name' and 'id'
	for employee in Global.employees:
		# Optional: Only show employees not already assigned elsewhere
		if employee_available(employee["id"]):
			$employee_list.add_item(employee["name"])

func employee_available(emp_id):
	# Check if employee already assigned in this popup
	return emp_id not in assigned_employees

func _on_employee_selected(index):
	var employee_name = $employee_list.get_item_text(index)
	# Find employee by name (or better by id in a real case)
	for emp in Global.employees:
		if emp["name"] == employee_name:
			assigned_employees[current_slot] = emp["id"]
			update_slot_button_text(current_slot, employee_name)
			break
	$employee_list.visible = false

func update_slot_button_text(slot_index, text):
	var slot_btn = get_node("VBoxContainer/HBoxContainer/slot_%d" % (slot_index + 1))
	slot_btn.text = text


func _on_close_pressed():
	hide()
	# TODO: Save assignments to Global or emit signal to update BuildingPage
