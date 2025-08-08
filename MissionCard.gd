extends Control

signal mission_started(mission_data)

@export var mission_name: String
@export var mission_id: String = ""
@export var period_seconds: int = 5
@export var reward_money: int = 100
@export var reward_xp: int = 10

@onready var start_button = $Panel/StartButton
@onready var employee_selector = $Panel/EmployeeSelector
@onready var reward_label = $Panel/RewardLabel
@onready var period_label = $Panel/PeriodLabel
@onready var title_label = $Panel/Title
@onready var time_left_label = $Panel/TimeLeftLabel
@onready var completed_label = $Panel/CompletedLabel
@onready var status_label = $Panel/StatusLabel

var mission_status := "available"
var selected_employee_index := -1
var duration := 0
var time_remaining := 0


var is_active := false
var assigned_employee_index := -1

func _ready():
	title_label.text = mission_name
	period_label.text = "Duration: %s sec" % period_seconds
	reward_label.text = "Reward: $%s, +%s XP" % [reward_money, reward_xp]
	
	_fill_employee_selector()
	start_button.pressed.connect(_on_start_pressed)
	
	_check_global_mission_status()
	Global.connect("mission_status_changed", Callable(self, "_on_global_mission_status_changed"))

func _on_global_mission_status_changed(changed_mission_name: String) -> void:
	if changed_mission_name == mission_name:
		_check_global_mission_status()

func set_mission_id(id: String) -> void:
	mission_id = id

var timer: Timer
func _start_timer():
	timer = Timer.new()
	timer.wait_time = 1
	timer.one_shot = false
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)
	timer.start()

func _on_timer_tick():
	if time_remaining > 0:
		time_remaining -= 1
		time_left_label.text = "⏳ " + str(time_remaining) + "s left"
	else:
		_complete_mission()


func _complete_mission():
	mission_status = "completed"
	time_remaining = 0
	_show_completed_state()

	# Update Global mission state by mission_id
	# mission_id is a String, so find index first
	for i in range(Global.mission_states.size()):
		if Global.mission_states[i].get("mission_id", "") == mission_id:
			Global.mission_states[i]["status"] = mission_status
			Global.mission_states[i]["time_remaining"] = time_remaining
			Global.mission_states[i]["employee_index"] = selected_employee_index
			Global.mission_states[i]["reward_money"] = reward_money
			break

	# Emit signal that mission completed (optional)
	emit_signal("mission_started", {
		"employee_index": selected_employee_index,
		"reward_money": reward_money,
		"mission_id": mission_id
	})

	# Stop your timer (assuming you stored it)
	if timer:
		timer.stop()
		timer.queue_free()
		timer = null

func _show_completed_state():
	print("Showing completed state! Hiding unneeded labels.")
	employee_selector.visible = false
	start_button.visible = false
	period_label.visible = false
	reward_label.visible = false
	time_left_label.visible = false
	status_label.visible = false
	completed_label.visible = true
	completed_label.text = "COMPLETED"




func _check_global_mission_status():
	var found := false
	for mission in Global.active_missions:
		if mission.get("mission_id", "") == mission_id:
			found = true
			is_active = true
			assigned_employee_index = mission.employee_index
			set_process(true)

			if mission.status == "active":
				start_button.text = "In Progress"
				start_button.disabled = true
				employee_selector.disabled = true
			elif mission.status == "completed":
				start_button.text = "Completed!"
				start_button.disabled = false
				employee_selector.disabled = true
			return

	# If no match found, reset to idle
	if not found:
		is_active = false
		set_process(false)
		start_button.text = "Start"
		start_button.disabled = false
		employee_selector.disabled = false
		time_left_label.text = "⏳ " + str(time_remaining) + "s left"



func _fill_employee_selector():
	employee_selector.clear()
	for i in range(Global.hired_employees.size()):
		var emp = Global.hired_employees[i]
		var label = "%s – %s" % [emp.name, emp.role]
		if Global.is_employee_busy(i):
			label += " (Busy)"
		employee_selector.add_item(label)
		employee_selector.set_item_disabled(i, Global.is_employee_busy(i))

func _on_start_pressed():
	if start_button.text == "Completed":
		_collect_rewards()
		return
	
	if is_active:
		return
	
	var selected = employee_selector.selected
	if selected == -1:
		return
	
	if not Global.is_employee_busy(selected):
		assigned_employee_index = selected
		Global.assign_mission_to_employee(assigned_employee_index, {
			"mission_id": mission_id,
			"mission_name": mission_name,
			"period_seconds": period_seconds,
			"reward_money": reward_money,
			"reward_xp": reward_xp
		})

		start_button.text = "In Progress"
		start_button.disabled = true
		employee_selector.disabled = true
		is_active = true
		set_process(true)
	else:
		print("Employee is busy!")


func _collect_rewards():
	if not is_active:
		return

	for mission in Global.active_missions:
		if mission.mission_name == mission_name and mission.status == "completed":
			Global.money += mission.reward_money
			Global.add_grid_xp(mission.reward_xp)
			Global.free_employee(mission.employee_index)
			Global.active_missions.erase(mission)
			break
	
	# Hide UI controls
	start_button.visible = false
	employee_selector.visible = false
	time_left_label.visible = false
	reward_label.visible = false
	period_label.visible = false
	title_label.visible = false
	
	completed_label.visible = true
	completed_label.text = "COMPLETED"

	is_active = false
	assigned_employee_index = -1


func _clear_card():
	if not is_active:
		return  # Don't clear unless this card is active and completed

	if start_button.text != "Completed!":
		return  # Don't clear unless the button says Completed!

	print("Clearing mission card...")

	# Hide all UI elements
	title_label.visible = false
	reward_label.visible = false
	period_label.visible = false
	start_button.visible = false
	employee_selector.visible = false
	time_left_label.visible = false

	# Add a completed label if not already added
	if not has_node("CompletedLabel"):
		var completed_label := Label.new()
		completed_label.text = "✅ Completed"
		completed_label.name = "CompletedLabel"
		completed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		completed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		completed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		completed_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(completed_label)

	# Reset internal state
	is_active = false
	assigned_employee_index = -1
	set_process(false)



func _process(_delta):
	if not is_active:
		return

	for mission in Global.active_missions:
		if mission.mission_name == mission_name:
			if mission.status == "active":
				var elapsed = Time.get_unix_time_from_system() - mission.start_time
				var remaining = max(0, mission.duration - elapsed)
				time_left_label.text = "Time Left: %s sec" % int(remaining)
			elif mission.status == "completed":
				start_button.text = "Completed"
				start_button.disabled = false
				time_left_label.text = "Time Left: 0 sec"
			return


# Called when a new day starts, resets mission state if needed
func reset_state():
	print("🔁 Resetting mission card:", mission_name)
	# (rest of your reset code)
	# Only reset if the mission was completed
	if mission_status == "completed":
		mission_status = "available"
		assigned_employee_index = -1
		start_button.text = "Start"
		start_button.visible = true
		start_button.disabled = false
		employee_selector.disabled = false
		employee_selector.select(-1)
		_fill_employee_selector()
		time_left_label.visible = false
		status_label.text = ""
		is_active = false

# Loads the mission state from Global
func load_from_state(state: Dictionary):
	print("Loading mission state: ", state)

	# Hide all optional UI first
	completed_label.visible = false
	status_label.visible = false
	time_left_label.visible = true
	period_label.visible = false
	reward_label.visible = false
	start_button.visible = true
	employee_selector.visible = true

	mission_name = state.mission_name
	mission_status = state.status
	assigned_employee_index = state.employee_index
	duration = state.duration
	reward_money = state.reward_money
	time_remaining = state.time_remaining

	if state.status == "completed":
		start_button.text = "Completed"
		start_button.disabled = false
		employee_selector.disabled = true
		_show_completed_state()
	elif state.status == "active":
		start_button.text = "In Progress"
		start_button.disabled = true
		employee_selector.disabled = true
		period_label.visible = true
		reward_label.visible = true
		time_left_label.visible = true
		completed_label.visible = false
		_start_timer()
	else:
		start_button.text = "Start"
		start_button.disabled = false
		employee_selector.disabled = false
		period_label.visible = true
		reward_label.visible = true
		time_left_label.visible = false
		completed_label.visible = false

	_fill_employee_selector()
	
	
func reset_all_missions():
	for mission_card in get_children():
		mission_card.reset_state()
