# Global.gd
extends Node

# ---------------------------
# Signals
# ---------------------------
signal mission_status_changed(mission_name: String)
signal employee_returned(employee_id: int)
signal money_changed(new_money: int)
signal floor_state_changed(floor_index: int)


# ---------------------------
# Preloads
# ---------------------------
const Employee = preload("res://Scenes/Shared/Employee.gd")
const EmployeeGenerator = preload("res://Scenes/Globals/EmployeeGenerator.gd")

# ---------------------------
# Employees 💪
# ---------------------------
var hired_employees: Array = []
var hire_candidates: Array = []
var next_employee_id: int = 0
var hire_candidates_day: int = -1

const NUM_EMPLOYEES_TO_GENERATE = 2  # candidates per day (excluding Day 1 fixed)

# ---------------------------
# Candidate generation
# ---------------------------
func get_hire_candidates() -> Array:
	# Only regenerate if day has changed
	if hire_candidates.size() == 0 or hire_candidates_day != day:
		generate_hire_candidates()
		hire_candidates_day = day
	return hire_candidates


func generate_hire_candidates():
	hire_candidates.clear()
	var generator = EmployeeGenerator.new()
	
	if day == 1:
		# Day 1 fixed employees
		var alice = Employee.new()
		alice.id = next_employee_id
		alice.name = "Alice"
		alice.role = "HR"
		alice.avatar = preload("res://Assets/Avatars/emp1.png")
		alice.proficiency = 3
		alice.level = 1
		alice.cost = 100
		alice.bio = "Intro: A fast learner with high potential, eager to take on challenges."
		next_employee_id += 1

		var bob = Employee.new()
		bob.id = next_employee_id
		bob.name = "Bob"
		bob.role = "Construction"
		bob.avatar = preload("res://Assets/Avatars/emp2.png")
		bob.proficiency = 2
		bob.level = 1
		bob.cost = 90
		bob.bio = "Intro: Reliable worker who keeps things running."
		next_employee_id += 1

		hire_candidates.append(alice)
		hire_candidates.append(bob)
	else:
		# Procedural candidates for Day > 1
		var generated = 0
		while generated < NUM_EMPLOYEES_TO_GENERATE:
			var new_emp = generator.generate_employee(next_employee_id)
			next_employee_id += 1

			# Avoid duplicates: same name + role + bio
			var duplicate = false
			for emp in hired_employees:
				if emp.name == new_emp.name and emp.role == new_emp.role and emp.bio == new_emp.bio:
					duplicate = true
					break
			if duplicate:
				continue

			hire_candidates.append(new_emp)
			generated += 1

# ---------------------------
# Employee utilities
# ---------------------------
func get_employee_by_id(emp_id: int) -> Employee:
	for emp in hired_employees:
		if emp.id == emp_id:
			return emp
	return null

func get_employee_index_by_id(emp_id: int) -> int:
	for i in range(hired_employees.size()):
		if hired_employees[i].id == emp_id:
			return i
	return -1

func is_employee_busy_by_id(emp_id: int) -> bool:
	var emp = get_employee_by_id(emp_id)
	if emp:
		return emp.is_busy
	return false

func mark_employee_busy(emp_id: int):
	var emp = get_employee_by_id(emp_id)
	if emp:
		emp.is_busy = true

func mark_employee_free(emp_id: int):
	var emp = get_employee_by_id(emp_id)
	if emp:
		emp.is_busy = false

func is_employee_available(emp_id: int) -> bool:
	for floor in building_floors:
		if "assigned_employee_indices" in floor and emp_id in floor["assigned_employee_indices"]:
			return false
	return not is_employee_busy_by_id(emp_id)

# ---------------------------
# Player / business state
# ---------------------------
var money: int = 1000
var stress: int = 0
var reputation: int = 0
var day: int = 1
var can_inspect: bool = true
var employee_capacity: int = 3
var grid_xp: int = 0

func set_money(value: int):
	money = value
	emit_signal("money_changed", money)

func add_grid_xp(amount: int):
	grid_xp += amount
	print("Grid XP is now:", grid_xp)

# ---------------------------
# Floors
# ---------------------------

var next_room_to_load: String = ""


func set_floor_state(floor_index: int, new_state: int):
	if floor_index < 0 or floor_index >= building_floors.size():
		push_error("Invalid floor index in set_floor_state: %d" % floor_index)
		return
	building_floors[floor_index]["state"] = new_state
	emit_signal("floor_state_changed", floor_index)

func ensure_building_floors_initialized():
	if building_floors.size() == 0:
		init_building_floors(13)



var current_floor_scene: String = ""

enum FloorState { LOCKED, AVAILABLE, READY, ASSIGNED }

var building_floors: Array = []


func init_building_floors(count: int = 6):
	if building_floors.size() > 0:
		return

	for i in range(count):
		var scene_path := ""
		var label_text := ""
		var state_val := FloorState.LOCKED

		match i:
			0:
				scene_path = "res://Scenes/Floors/Floor1.tscn"
				label_text = "Floor 1"
				state_val = FloorState.AVAILABLE  # Only Floor1 unlocked
			1:
				scene_path = "res://Scenes/Floors/Floor2.tscn"
				label_text = "Floor 2"
				state_val = FloorState.LOCKED
			2:
				scene_path = "res://Scenes/Floors/Floor3.tscn"
				label_text = "Floor 3"
				state_val = FloorState.LOCKED
			3:
				scene_path = "res://Scenes/Floors/Floor4.tscn"
				label_text = "Floor 4"
				state_val = FloorState.LOCKED
			4:
				scene_path = "res://Scenes/Floors/Floor5.tscn"
				label_text = "Floor 5"
				state_val = FloorState.LOCKED
			5:
				scene_path = "res://Scenes/Floors/Floor6.tscn"
				label_text = "Floor 6"
				state_val = FloorState.LOCKED

		var floor := {
			"scene": scene_path,
			"label": label_text,
			"state": state_val,
			"purpose": "",
			"capacity": 3,
			"assigned_employee_indices": []
		}

		# Pre-fill slots with nulls based on capacity
		for j in range(floor["capacity"]):
			floor["assigned_employee_indices"].append(null)

		building_floors.append(floor)



func set_floor(floor_name: String):
	current_floor_scene = floor_name
	print("Global: current floor set to ", floor_name)


# ---------------------------
# Missions
# ---------------------------
var mission_data: Array = []
var active_missions: Array = []

func assign_mission_to_employee(emp_id: int, mission_info: Dictionary):
	var emp_index = get_employee_index_by_id(emp_id)
	if emp_index == -1 or is_employee_busy_by_id(emp_id):
		return

	var data = {
		"employee_id": emp_id,
		"start_time": Time.get_unix_time_from_system(),
		"duration": mission_info.get("period_seconds", 0),
		"mission_name": mission_info.get("mission_name", ""),
		"mission_id": mission_info.get("mission_id", ""),
		"reward_money": mission_info.get("reward_money", 0),
		"reward_xp": mission_info.get("reward_xp", 0),
		"status": "active"
	}
	active_missions.append(data)
	hired_employees[emp_index].is_busy = true

func free_employee_from_mission(emp_id: int):
	var emp_index = get_employee_index_by_id(emp_id)
	if emp_index != -1:
		hired_employees[emp_index].is_busy = false

func check_mission_statuses():
	var now = Time.get_unix_time_from_system()
	for mission in active_missions:
		if mission.status == "active":
			var elapsed = now - mission.start_time
			if elapsed >= mission.duration:
				mission.status = "completed"
				emit_signal("mission_status_changed", mission.mission_name)
				free_employee_from_mission(mission.employee_id)
				emit_signal("employee_returned", mission.employee_id)

# ---------------------------
# Misc
# ---------------------------
func clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()



# ---------------------------
# HR
# ---------------------------
# At the top of Global.gd
var HR_state := {
	"locked_images": {
		"department": true,
		"hiring": true,
		"staff": true,
		"bulletin": true
	},
	"selected": {
		"department": false,
		"hiring": false,
		"staff": false,
		"bulletin": false
	}
}

# ---------------------------
# Maintenance
# ---------------------------
var Maintenance_state := {
	"locked_images": {
		"department": false,
		"tower": false,
		"techtree": false,
	},
	"selected": {
		"department": false,
		"tower": false,
		"techtree": false,
	}
}
