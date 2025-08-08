extends Control  # Or Node2D depending on your root

@onready var day_label = $HUD/DayLabel
@onready var day_start_sound = $HUD/DayStartSound

@onready var building_page_scene = preload("res://Building.tscn")
@onready var operations_page_scene = preload("res://OperationsPage.tscn")

@onready var grid_page_scene = preload("res://grid_page.tscn")

@onready var black_overlay = $HUD/BlackOverlay
@onready var work_button = $HUD/VBoxContainer/WorkButton

@onready var employee_container = $Characters/Employees

var employee_scene := preload("res://Employee.tscn")
@onready var employee_spawn_point = $Characters/EmployeeSpawnPoint

@export var floor_scene: PackedScene
@onready var floors_container = $FloorsContainer
@onready var scroll_container = $HUD/ElevatorUI/ScrollContainer

@onready var elevator_ui = $HUD/ElevatorUI
@onready var grid_button = $GridButton


func get_random_spawn_position() -> Vector2:
	var base_pos = employee_spawn_point.global_position
	var x_offset = randf_range(-100, 100)
	return Vector2(base_pos.x + x_offset, base_pos.y)

func spawn_employees():
	clear_children(employee_container)
	var employee_scene = preload("res://Employee.tscn")

	for i in range(Global.hired_employees.size()):
		var emp = employee_scene.instantiate()
		emp.employee_index = i
		emp.name = "employee_%d" % i
		emp.global_position = get_random_spawn_position()
		employee_container.add_child(emp)

func hide_busy_employees():
	for emp in $Characters/Employees.get_children():
		if Global.is_employee_busy(emp.employee_index):
			emp.visible = false
		else:
			emp.visible = true



func _on_grid_button_pressed() -> void:
	print("🟩 Grid button pressed – switching to grid_page.tscn")

	var scene_path = "res://grid_page.tscn"
	var error = get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("❌ Failed to load scene: " + scene_path)


func _on_building_button_pressed():
	get_tree().change_scene_to_packed(building_page_scene)

func _on_operations_button_pressed():
	get_tree().change_scene_to_packed(operations_page_scene)


# Game variables
var employee_page_scene = preload("res://EmployeePage.tscn")

var stress = 0
var reputation = 0

var employees = []
var all_roles = ["Engineer", "Artist", "Designer", "Support"]

var last_day_base_income := 0
var last_day_employee_income := 0

var employee_capacity = 3  # Starting capacity

func update_hud():
	$HUD/MoneyLabel.text = str(Global.money)
	$HUD/EmployeeCapacityLabel.text = str(Global.hired_employees.size()) + " / " + str(Global.employee_capacity)

var current_floor_instance: Node = null

func _on_floor_selected(floor_index: int) -> void:
	print("Game.gd: Floor selected:", floor_index)
	fade_switch_floor(floor_index)
	if scroll_container:
		scroll_container.visible = false

func _ready():
	print("MainPage ready!")

	# Connect floor_selected signal from ElevatorUI to this scene's handler
	$ElevatorUI.floor_selected.connect(Callable(self, "_on_floor_selected"))

	# Clear existing floors
	if floors_container:
		for child in floors_container.get_children():
			child.queue_free()
	else:
		push_error("❌ floors_container node not found!")
		return

	var floor_scene_paths = [
		"res://floors/Floor1_Work.tscn",
		"res://floors/Floor2_Training.tscn",
		"res://floors/Floor3_HR.tscn",
		# Add more floor paths here
	]

	for i in range(floor_scene_paths.size()):
		var scene_path = floor_scene_paths[i]
		var floor_scene = load(scene_path)
		if floor_scene:
			var floor_instance = floor_scene.instantiate()
			floor_instance.name = "Floor_%d" % (i + 1)
			if "floor_number" in floor_instance:
				floor_instance.floor_number = i + 1
			floor_instance.visible = false
			floors_container.add_child(floor_instance)
			print("✅ Loaded floor scene: ", scene_path)
		else:
			push_error("❌ Failed to load floor scene: " + scene_path)

	# Default floor index
	if not ("current_floor_index" in Global):
		Global.current_floor_index = 0

	# Show initial floor
	switch_to_floor(Global.current_floor_index)

	# Elevator UI setup
	if elevator_ui:
		elevator_ui.current_floor = Global.current_floor_index
		elevator_ui.update_floor_button()
	else:
		push_error("❌ ElevatorUI node not found!")

	# Grid button signal
	if grid_button:
		var callable = Callable(self, "_on_grid_button_pressed")
		if grid_button.pressed.is_connected(callable):
			grid_button.pressed.disconnect(callable)
		grid_button.pressed.connect(callable)
		print("🔗 Connected GridButton")
	else:
		push_error("❌ GridButton node not found!")

	# Connect Global singleton signals
	Global.connect("money_changed", Callable(self, "_on_money_changed"))
	Global.connect("mission_status_changed", Callable(self, "_on_mission_status_changed"))
	Global.connect("employee_returned", Callable(self, "_on_employee_returned"))

	# UI logic
	update_ui()

	if Global.hire_candidates.size() == 0:
		generate_daily_employees()
	else:
		update_employee_buttons()

	# Debug test label
	var test_label = Label.new()
	test_label.text = "Test hired employee"
	if $HUD.has_node("HiredList"):
		$HUD/HiredList.add_child(test_label)

	hide_busy_employees()
	update_employee_list_ui()
	update_hud()



func _on_employee_returned(employee_index: int):
	print("Employee returned:", employee_index)
	
	for emp in employee_container.get_children():
		if emp.employee_index == employee_index:
			emp.visible = true
			# Play teleport animation if you want
			var anim_sprite = emp.get_node("AnimatedSprite2D")
			if anim_sprite:
				anim_sprite.play("teleport")
			return
	
	# If not found, respawn all employees (optional)
	spawn_employees()
	hide_busy_employees()

func _on_mission_status_changed(mission_name: String) -> void:
	hide_busy_employees()
	
func return_employee_to_game(employee_index: int):
	var employee_scene = preload("res://Employee.tscn")
	var employee = employee_scene.instantiate()
	employee.employee_index = employee_index
	employee.name = "employee_%d" % employee_index
	employee.position = get_random_spawn_position()

	$Characters/Employees.add_child(employee)

	# Play teleport animation and delay movement
	var anim_sprite = employee.get_node("AnimatedSprite2D")
	if anim_sprite:
		employee.teleporting = true  # Set the teleporting flag so movement is paused
		anim_sprite.play("teleport")
		await anim_sprite.animation_finished
		employee.teleporting = false



	
func _on_money_changed(new_money):
	update_ui()
	
func update_employee_list_ui():
	clear_children($HUD/HiredList)
	for emp in Global.hired_employees:
		var label = Label.new()
		label.text = "%s – %s (+$%d/day)" % [emp.name, emp.role, emp.boost]
		$HUD/HiredList.add_child(label)

func update_ui():
	
	
	
	$HUD/EmployeeCapacityLabel.text = "Employees: %d / %d" % [Global.hired_employees.size(), employee_capacity]
	$HUD/MoneyLabel.text = "Money: $" + str(Global.money)
	$HUD/DayLabel.text = "Day: " + str(Global.day)
	$HUD/VBoxContainer/MoneyLabel.text = "Money: $" + str(Global.money)
	$HUD/VBoxContainer/TimeLabel.text = "Time: Day " + str(Global.day)
	$HUD/VBoxContainer/StatsLabel.text = "Stats: Stress " + str(Global.stress) + " / Rep " + str(Global.reputation)
	$HUD/EmployeeCapacityLabel.text = "Employees: %d / %d" % [Global.hired_employees.size(), Global.employee_capacity]


func some_update_function():
	Global.money += 100


func _on_work_button_pressed():
	fade_to_black_and_process_day()
	generate_daily_employees()



func fade_to_black_and_process_day():

	black_overlay.visible = true
	day_label.visible = false
	await get_tree().create_timer(1.0).timeout

	# Advance game state by calling next_day()
	next_day()

	# Hide black overlay after updating UI and showing report
	black_overlay.visible = false

	# Show the "Day X Begins..." message
	day_label.text = "Day " + str(Global.day) + " Begins..."
	day_label.visible = true
	
	day_start_sound.play()  # 🔊 Play the sound here


	await get_tree().create_timer(1.5).timeout  # hold the text for a moment
	day_label.visible = false
	black_overlay.visible = false


#Employees

	#workday logic
func next_day():
	Global.day += 1
	Global.should_reset_missions = true
	print("📅 Day advanced to: ", Global.day)

	# Reset missions in GridPage once
	var grid_page = get_node_or_null("GridPage") or get_node_or_null("/root/Game/GridPage")
	if grid_page:
		print("📢 Resetting GridPage missions for new day")
		grid_page.reset_missions_for_new_day()
	else:
		print("⚠️ GridPage not found")

	# 💰 Income calculation
	var base_income = 300
	var work_income = 0

	for floor in Global.building_floors:
		if floor.get("unlocked", false) and floor.get("type", "") == "work":
			var num_workers = floor.get("assigned_employee_indices", []).filter(func(i): return i != null).size()
			work_income += num_workers * 100  # ← You can tweak this value

	var total_income = base_income + work_income
	Global.money += total_income

	# Store for report
	last_day_base_income = base_income
	last_day_employee_income = work_income

	# ⏳ Progress missions
	for mission in Global.mission_data:
		if !mission.complete:
			mission.days_left -= 1
			if mission.days_left <= 0:
				mission.complete = true
				return_employee_to_game(mission.employee_id)

	# ✅ Final updates
	Global.reset_all_missions()
	update_ui()
	show_daily_report()


	#Daily Report
func show_daily_report():
	print("show_daily_report() called")  # Debug print

	var report_title = "S Tier Work Day"  # You can make this dynamic later
	var total_profit = last_day_base_income + last_day_employee_income
	var breakdown_text = "Total Profit: $" + str(total_profit) + "\n"
	breakdown_text += "- Base Operations: $" + str(last_day_base_income) + "\n"
	breakdown_text += "- Employee Impact: $" + str(last_day_employee_income)

	$HUD/DailyReport/VBoxContainer/TitleLabel.text = report_title
	$HUD/DailyReport/VBoxContainer/BreakdownLabel.text = breakdown_text
	$HUD/DailyReport.visible = true
	
	print("DailyReport visible set to true")

func _on_close_button_pressed() -> void:
	$HUD/DailyReport.visible = false


	#income logic
func calculate_daily_income():
	var income = 25  # Base income each day
	for emp in Global.hired_employees:
		income += emp.boost
	return income
	#generate employees daily
func generate_random_name():
	var names = ["Julia", "Max", "Casey", "Devon", "Sam", "Morgan", "Taylor", "Jordan"]
	return names[randi() % names.size()]

func generate_daily_employees():
	Global.hire_candidates.clear()

	var default_avatar_frames = preload("res://Employee.tres") # 🧠 adjust path if needed

	for i in range(3):
		var role = all_roles[randi() % all_roles.size()]
		var name = generate_random_name()
		var cost = randi() % 151 + 100  # $100–250
		var boost = randi() % 16 + 5    # $5–20/day

		var emp_data = {
			"id": i + 1,
			"name": name,
			"role": role,
			"cost": cost,
			"boost": boost,
			"is_busy": false,
			"avatar_frames": default_avatar_frames  # 🎨 add avatar!
		}

		Global.hire_candidates.append(emp_data)

	update_employee_buttons()

	
func get_productivity_label(boost: int) -> String:
	if boost < 8:
		return "Low"
	elif boost < 14:
		return "Medium"
	else:
		return "High"
	#employee names


	#Update Employees

func update_employee_buttons():
	for i in range(Global.hire_candidates.size()):
		var emp = Global.hire_candidates[i]
		var btn = $HUD/EmployeeList.get_child(i)
		
		if emp != null:
			btn.text = "%s – %s\n💵 $%d – Productivity: %s" % [
				emp.name, emp.role, emp.cost, get_productivity_label(emp.boost)
			]
			btn.disabled = false
		else:
			btn.text = "✅ Already Hired"
			btn.disabled = true


	#Employee buttons
func _on_employee_1_pressed() -> void:
	print("Button 1 clicked!")
	hire_employee(0)
	pass # Replace with function body.


func _on_employee_2_pressed() -> void:
	print("Button 1 clicked!")
	hire_employee(1)
	pass # Replace with function body.


func _on_employee_3_pressed() -> void:
	print("Button 1 clicked!")
	hire_employee(2)
	pass # Replace with function body.


func hire_employee(index):
	if Global.hired_employees.size() >= Global.employee_capacity:
		$HUD/EmployeeList.get_child(index).text = "❌ Capacity reached!"
		return

	var emp = Global.hire_candidates[index]
	if emp == null:
		return

	if Global.money >= emp.cost:
		Global.money -= emp.cost
		Global.hired_employees.append(emp)
		Global.hire_candidates[index] = null  # Mark as hired

		var btn = $HUD/EmployeeList.get_child(index)
		btn.text = "✅ Hired: %s" % emp.name
		btn.disabled = true

		var hired_label = Label.new()
		hired_label.text = "✅ %s – %s (+$%d/day)" % [emp.name, emp.role, emp.boost]
		$HUD/HiredList.add_child(hired_label)

		update_hired_employees_ui()
		update_ui()
		spawn_employees()
	else:
		$HUD/EmployeeList.get_child(index).text = "❌ Not enough money"

func clear_children(node):
	for child in node.get_children():
		child.queue_free()

		
func update_hired_employees_ui():
	clear_children($HUD/HiredList)
	for i in range(Global.hired_employees.size()):
		var emp = Global.hired_employees[i]
		
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = "%s – %s (+$%d/day)" % [emp.name, emp.role, emp.boost]
		hbox.add_child(label)
		
		var fire_button = Button.new()
		fire_button.text = "Fire"
		fire_button.connect("pressed", Callable(self, "_on_fire_employee_pressed").bind(i))
		hbox.add_child(fire_button)
		
		$HUD/HiredList.add_child(hbox)

func _on_fire_employee_pressed(index):
	var emp = Global.hired_employees[index]
	Global.hired_employees.remove_at(index)
	print("Fired: %s" % emp.name)
	
	update_hired_employees_ui()
	update_ui()

func _on_manage_employees_pressed() -> void:
	get_tree().change_scene_to_packed(employee_page_scene)


var target_floor_index = 0

func fade_switch_floor(floor_index):
	print("Game.gd: fade_switch_floor called with floor %d" % (floor_index + 1))
	target_floor_index = floor_index
	$HUD/FadeRect.visible = true
	$HUD/FadeRect.modulate.a = 0
	var tween = create_tween()
	tween.tween_property($HUD/FadeRect, "modulate:a", 1, 0.5)
	tween.tween_callback(Callable(self, "_on_fade_out_complete"))

func _on_fade_out_complete():
	print("Game.gd: fade out complete, switching floor")
	switch_to_floor(target_floor_index)
	var tween = create_tween()
	tween.tween_property($HUD/FadeRect, "modulate:a", 0, 0.5)
	tween.tween_callback(Callable(self, "_on_fade_in_complete"))

func _on_fade_in_complete():
	print("Game.gd: fade in complete")
	$HUD/FadeRect.visible = false

func switch_to_floor(floor_index: int) -> void:
	# Hide all existing floors
	for floor in floors_container.get_children():
		floor.visible = false

	# Build the expected node name
	var floor_name = "Floor_%d" % (floor_index + 1)

	# Try to get that floor node
	var floor_node = floors_container.get_node_or_null(floor_name)
	if floor_node:
		floor_node.visible = true
		Global.current_floor_index = floor_index
		print("✅ Switched to floor:", floor_name)

		# Update elevator UI, if it exists
		if elevator_ui:
			elevator_ui.current_floor = floor_index
			elevator_ui.update_floor_button()
	else:
		push_error("❌ Floor node not found: " + floor_name)

	# Optional: print debug list of floor names
	# Uncomment if you need it
	# for f in floors_container.get_children():
	#     print("Floor in container:", f.name)



func populate_floor_list():
	var floor_list = $HUD/ElevatorUI/ScrollContainer/FloorList
	clear_children(floor_list)

	var total_floors = 10  # Or get this dynamically

	for i in range(total_floors):
		var btn = Button.new()
		btn.text = "Floor %d" % (i + 1)
		btn.name = "floor_btn_%d" % i
		floor_list.add_child(btn)
		print("Game.gd: Created button for Floor %d" % (i + 1))


	
func _on_floor_selector_pressed():
	var scroll = $HUD/ElevatorUI/ScrollContainer
	if scroll:
		scroll.visible = !scroll.visible
	else:
		print("ScrollContainer node not found!")
		
		
		
func _on_static_employee_conversation_started(data: Dictionary) -> void:
	var convo = $HUD/EmployeeConversation

	convo.show_conversation(data["text"], data["choices"][0], data["choices"][1])

	# Proper is_connected check with Callable for Godot 4+
	if not convo.is_connected("choice_made", Callable(self, "_on_conversation_result")):
		convo.choice_made.connect(Callable(self, "_on_conversation_result"))


func _on_conversation_result(result: String) -> void:
	print("Player chose: ", result)
	
	# Fake result handling for now
	if result == "Sure, go ahead.":
		print("Hype++")
	else:
		print("Maybe next time...")

	# TODO: Add employee mood logic or animation here

func _connect_employee_signals(floor_instance):
	for child in floor_instance.get_children():
		if child.has_signal("conversation_started"):
			child.conversation_started.connect(Callable(self, "_on_static_employee_conversation_started"))
