#EmployeePage


extends Control

@onready var employee_list_container = $EmployeeListContainer
@onready var action_panel = $ActionPanel
@onready var selected_employee_label = $ActionPanel/SelectedEmployeeLabel
@onready var confirm_popup = $ConfirmPopup

@onready var fire_button = $ActionPanel/FireButton
@onready var inspect_button = $ActionPanel/InspectButton
@onready var talk_button = $ActionPanel/TalkButton


var selected_employee_index := -1

func default_box_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25)
	style.border_width_all = 2
	style.border_color = Color(0.6, 0.6, 0.6)
	return style

func selected_box_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.4)
	style.border_width_all = 3
	style.border_color = Color(1, 0.8, 0.2)  # Gold highlight
	return style


func _ready():
	print("EmployeePage ready")
	$BackButton.connect("pressed", Callable(self, "_on_back_button_pressed"))

	fire_button.disabled = true
	inspect_button.disabled = true
	talk_button.disabled = true

	inspect_button.connect("pressed", Callable(self, "_on_inspect_button_pressed"))
	talk_button.connect("pressed", Callable(self, "_on_talk_button_pressed"))
	fire_button.connect("pressed", Callable(self, "_on_fire_button_pressed"))
	confirm_popup.connect("confirmed", Callable(self, "_on_confirm_popup_confirmed"))

	update_employee_list_ui()
	reset_action_panel()


	#reset_action_panel()
	
func _on_back_button_pressed():
	print("Back button pressed")
	get_tree().change_scene_to_file("res://Game.tscn")  # Your main scene



func _on_fire_employee_pressed(index):
	Global.hired_employees.remove_at(index)
	# Optional: Update other UI here if needed

func clear_children(node):
	for child in node.get_children():
		child.queue_free()
		


func _on_employee_selected(index: int):
	selected_employee_index = index
	var emp = Global.hired_employees[index]

	selected_employee_label.text = "%s\n%s\n+$%d/day" % [emp.name, emp.role, emp.boost]

	for i in range(employee_list_container.get_child_count()):
		var child = employee_list_container.get_child(i)
		if child is Button:
			if i == index:
				var selected_style = StyleBoxFlat.new()
				selected_style.bg_color = Color(0.4, 0.4, 0.6)
				selected_style.set_border_width(SIDE_LEFT, 3)
				selected_style.set_border_width(SIDE_TOP, 3)
				selected_style.set_border_width(SIDE_RIGHT, 3)
				selected_style.set_border_width(SIDE_BOTTOM, 3)
				selected_style.border_color = Color(1, 0.8, 0.2)
				child.add_theme_stylebox_override("normal", selected_style)
			else:
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.2, 0.2, 0.3)
				style.set_border_width(SIDE_LEFT, 2)
				style.set_border_width(SIDE_TOP, 2)
				style.set_border_width(SIDE_RIGHT, 2)
				style.set_border_width(SIDE_BOTTOM, 2)
				style.border_color = Color(1, 1, 1)
				child.add_theme_stylebox_override("normal", style)

	fire_button.disabled = false
	inspect_button.disabled = false
	talk_button.disabled = false






func _on_fire_button_pressed():
	if selected_employee_index == -1:
		return
	confirm_popup.popup_centered()


func _on_confirm_popup_confirmed():
	if selected_employee_index == -1:
		return

	Global.hired_employees.remove_at(selected_employee_index)
	selected_employee_index = -1
	update_employee_list_ui()
	reset_action_panel()

		
func _on_inspect_button_pressed():
	print("Inspecting employee: %s" % Global.hired_employees[selected_employee_index].name)
	# Add your inspect logic here

func _on_talk_button_pressed():
	print("Talking to employee: %s" % Global.hired_employees[selected_employee_index].name)
	# Add your talk logic here

func reset_action_panel():
	selected_employee_label.text = "Select an employee"
	fire_button.disabled = true
	inspect_button.disabled = true
	talk_button.disabled = true











func update_employee_list_ui():
	for child in employee_list_container.get_children():
		child.queue_free()

	for i in range(Global.hired_employees.size()):
		var emp = Global.hired_employees[i]
		if emp == null:
			continue

		var button = Button.new()
		button.name = "EmployeeButton_%d" % i
		button.text = "%s\n%s\n+$%d/day" % [emp.name, emp.role, emp.boost]
		button.custom_minimum_size = Vector2(300, 100)
		button.flat = false
		button.focus_mode = Control.FOCUS_NONE

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.3)
		style.set_border_width(SIDE_LEFT, 2)
		style.set_border_width(SIDE_TOP, 2)
		style.set_border_width(SIDE_RIGHT, 2)
		style.set_border_width(SIDE_BOTTOM, 2)
		style.border_color = Color(1, 1, 1)
		button.add_theme_stylebox_override("normal", style)

		button.connect("pressed", Callable(self, "_on_employee_selected").bind(i))

		employee_list_container.add_child(button)

func select_employee(index):
	selected_employee_index = index
	var emp = Global.hired_employees[index]
	
	# Update selected employee label
	selected_employee_label.text = "%s\n%s\n+$%d/day" % [emp.name, emp.role, emp.boost]
	
	# Enable buttons
	inspect_button.disabled = false
	talk_button.disabled = false
	fire_button.disabled = false


func _on_employee_box_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_employee(index)
