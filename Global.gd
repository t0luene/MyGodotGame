# Global.gd
extends Node

# ---------------------------
# Signals
# ---------------------------
signal mission_status_changed(mission_name: String)
signal employee_returned(employee_id: int)
signal money_changed(new_money: int)

# ---------------------------
# Preloads
# ---------------------------
const Employee = preload("res://Scenes/Shared/Employee.gd")

# ---------------------------
# Employees
# ---------------------------
var hired_employees: Array = []
var hire_candidates: Array = []
var next_employee_id: int = 0
const NUM_EMPLOYEES_TO_GENERATE = 3


func generate_hire_candidates():
	hire_candidates.clear()
	
	# Hardcoded HR and Maintenance
	var alice = Employee.new()
	alice.id = next_employee_id
	alice.name = "Alice"
	alice.role = "HR"
	alice.avatar = preload("res://Assets/Avatars/emp1.png")
	alice.proficiency = 80
	alice.cost = 100
	alice.bio = """Summary:
A fast learner with a knack for organization.

Skills:
- HR coordination
- Communication
- Scheduling

Experience:
- HR Assistant at BrightFuture Inc. (2 years)

Education:
- B.A. in Business Administration

Hobbies:
- Reading
- Hiking
"""
	next_employee_id += 1

	var bob = Employee.new()
	bob.id = next_employee_id
	bob.name = "Bob"
	bob.role = "Maintenance"
	bob.avatar = preload("res://Assets/Avatars/emp2.png")
	bob.proficiency = 65
	bob.cost = 90
	bob.bio = """Summary:
Reliable worker who keeps things running.

Skills:
- Electrical repairs
- Plumbing
- Preventative maintenance

Experience:
- Maintenance Tech at ClearPath Ltd. (3 years)

Education:
- High School Diploma

Hobbies:
- Gardening
- DIY
"""
	next_employee_id += 1

	hire_candidates.append(alice)
	hire_candidates.append(bob)

	# Generic candidates
	for i in range(NUM_EMPLOYEES_TO_GENERATE):
		var candidate = Employee.new()
		candidate.id = next_employee_id
		candidate.name = "Candidate_" + str(next_employee_id)
		candidate.role = "Role_" + str(next_employee_id)
		candidate.cost = 100 + next_employee_id * 10
		candidate.proficiency = 50 + next_employee_id * 5
		candidate.is_busy = false
		candidate.bio = "A generic candidate for testing purposes."
		hire_candidates.append(candidate)
		next_employee_id += 1


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
var building_floors = {
	"HR": {
		"assigned_employee_indices": [null, null, null, null, null, null]
	},
	"Maintenance": {
		"assigned_employee_indices": [null, null, null, null, null, null]
	}
}

var current_floor_scene: String = ""

const FloorState = {
	"LOCKED": 0,
	"AVAILABLE": 1,
	"READY": 2,
	"ASSIGNED": 3
}

func init_building_floors(count: int = 6):
	if building_floors.size() > 0:
		return
	for i in range(count):
		var scene_path = ""
		var label_text = ""
		var state_val = FloorState.LOCKED
		match i:
			0:
				scene_path = "res://Scenes/Floors/Floor-1.tscn"
				label_text = "Floor -1"
				state_val = FloorState.AVAILABLE
			1:
				scene_path = "res://Scenes/Floors/Floor0.tscn"
				label_text = "Floor 0"
				state_val = FloorState.AVAILABLE
			2:
				scene_path = "res://Scenes/Floors/Floor1.tscn"
				label_text = "Floor 1"
			3:
				scene_path = "res://Scenes/Floors/Floor2.tscn"
				label_text = "Floor 2"
			4:
				scene_path = "res://Scenes/Floors/Floor3.tscn"
				label_text = "Floor 3"
			5:
				scene_path = "res://Scenes/Floors/Floor4.tscn"
				label_text = "Floor 4"

		var floor = {
			"scene": scene_path,
			"label": label_text,
			"state": state_val,
			"purpose": null,
			"capacity": 3,
			"assigned_employee_indices": []
		}
		
		# Initialize assigned_employee_indices with nulls matching capacity
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
