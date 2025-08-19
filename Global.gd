# Global.gd
extends Node

signal mission_status_changed(mission_name: String)
signal employee_returned(employee_index)

# Global player/business state
var money: int = 1000
var stress: int = 0
var reputation: int = 0
var day: int = 1
var current_floor_index: int = 0

var employees = [
	{"id": 1, "name": "Luigi"},
	{"id": 2, "name": "Mario"},
	# add more employees here...
]
var can_inspect := true  # whether the player can inspect floors today


var hired_employees: Array = []
var next_employee_id: int = 0
const NUM_EMPLOYEES_TO_GENERATE = 3

func generate_daily_employees():
	for i in range(NUM_EMPLOYEES_TO_GENERATE):
		var emp = {
			"id": next_employee_id,
			"name": "Employee_" + str(next_employee_id),
			"role": "Role_" + str(next_employee_id),
			"cost": 100 + next_employee_id * 10,
			"boost": 5 + next_employee_id,
			"is_busy": false,
		}
		hired_employees.append(emp)
		next_employee_id += 1

var employee_capacity: int = 3
var building_floors: Array = []  # Will hold floor info
var hire_candidates: Array = []

# Constants
const FLOOR_COST = 500
const MAX_EMPLOYEE_CAPACITY = 20
const BASE_OPERATIONS_COST = 100

var unlocked_floors: Array = []

var busy_employee_ids := []  # store indexes or unique IDs of busy employees
var mission_start_buffer := 1 # seconds of delay before it can be marked complete

var should_reset_missions := false
var mission_data: Array = []

const FloorState = {
	"LOCKED": 0,
	"AVAILABLE": 1,
	"READY": 2,
	"ASSIGNED": 3
}

func ensure_floors_initialized(count: int = 5):
	if building_floors.size() == 0:
		for i in range(count):
			var floor = {
				"state": FloorState.AVAILABLE if i == 0 else FloorState.LOCKED,
				"purpose": null,
				"capacity": 3,
				"assigned_employee_indices": []
			}
			building_floors.append(floor)



func add_mission(employee_id: String, days: int):
	mission_data.append({
		"employee_id": employee_id,
		"days_left": days,
		"complete": false
	})

func is_employee_on_mission(employee_id: String) -> bool:
	for mission in mission_data:
		if mission.employee_id == employee_id and !mission.complete:
			return true
	return false


func assign_employee_to_mission(index):
	if not is_employee_busy(index):
		busy_employee_ids.append(index)

func free_employee_from_mission(index):
	busy_employee_ids.erase(index)



signal money_changed(new_money)


func set_money(value):
	money = value
	emit_signal("money_changed", money)

var mission_states = [
	{
		"mission_name": "Mission 1",
		"status": "available",
		"employee_index": -1,
		"duration": 5,
		"reward_money": 100,
		"time_remaining": 0
	},
	{
		"mission_name": "Mission 2",
		"status": "available",
		"employee_index": -1,
		"duration": 3,
		"reward_money": 80,
		"time_remaining": 0
	},
	{
		"mission_name": "Mission 3",
		"status": "available",
		"employee_index": -1,
		"duration": 4,
		"reward_money": 120,
		"time_remaining": 0
	}
]
func reset_all_missions():
	for state in mission_states:
		state["status"] = "available"
		state["employee_index"] = -1
		state["time_remaining"] = 0
		state["active"] = false
		state["completed"] = false
		state["employee"] = null


var active_missions: Array = [] # Stores mission dictionaries

func assign_mission_to_employee(index: int, mission_data: Dictionary):
	var data = {
	"employee_index": index,
	"start_time": Time.get_unix_time_from_system(),
	"duration": mission_data["period_seconds"],
	"mission_name": mission_data["mission_name"],
	"mission_id": mission_data["mission_id"],
	"reward_money": mission_data["reward_money"],
	"reward_xp": mission_data["reward_xp"],
	"status": "active"
}

	active_missions.append(data)
	for i in range(mission_states.size()):
		if mission_states[i].get("mission_name", "") == data["mission_name"]:
			mission_states[i]["status"] = "active"
			mission_states[i]["employee_index"] = index
			mission_states[i]["time_remaining"] = data["duration"]
			break

	hired_employees[index]["is_busy"] = true



func check_mission_statuses():
	var now = Time.get_unix_time_from_system()
	for mission in active_missions:
		if mission.status == "active":
			var elapsed = now - mission.start_time
			if elapsed >= mission.duration:
				mission.status = "completed"
				emit_signal("mission_status_changed", mission.mission_name)
				
				Global.free_employee(mission.employee_index)
				
				# Emit a new signal for employee return
				emit_signal("employee_returned", mission.employee_index)

				# Update mission_states to completed
				for i in range(mission_states.size()):
					if mission_states[i].get("mission_name", "") == mission.mission_name:
						mission_states[i]["status"] = "completed"
						mission_states[i]["time_remaining"] = 0
						break



func is_employee_busy(index: int) -> bool:
	if index < 0 or index >= hired_employees.size():
		return false
	return hired_employees[index].get("is_busy", false)

	
func free_employee(index: int):
	hired_employees[index]["is_busy"] = false

func _process(delta):
	check_mission_statuses()

var grid_xp := 0

func add_grid_xp(amount: int):
	grid_xp += amount
	print("Grid XP is now:", grid_xp)

# Example initial state (in Global.gd)


func get_employee_by_id(id):
	for emp in hired_employees:
		if emp.get("id", -1) == id:
			return emp
	return null

func get_employee_id_by_name(name):
	for i in range(hired_employees.size()):
		if hired_employees[i].get("name", "") == name:
			return i
	return -1  # not found


func is_employee_available(id):
	for floor in building_floors:
		if floor.has("assigned_employee_indices") and id in floor["assigned_employee_indices"]:
			return false
	return not is_employee_busy_by_id(id)

func is_employee_busy_by_id(emp_id: int) -> bool:
	for i in range(hired_employees.size()):
		if hired_employees[i].get("id") == emp_id:
			return hired_employees[i].get("is_busy", false)
	return false


func mark_employee_busy(emp_id: int):
	for emp in hired_employees:
		if emp.get("id", -1) == emp_id:
			emp["is_busy"] = true
			return

func mark_employee_free(emp_id: int):
	for emp in hired_employees:
		if emp.get("id", -1) == emp_id:
			emp["is_busy"] = false
			return

func get_employee_index_by_id(emp_id: int) -> int:
	for i in range(hired_employees.size()):
		if hired_employees[i].get("id", -1) == emp_id:
			return i
	return -1

func clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()

func generate_hire_candidates():
	hire_candidates.clear()
	for i in range(NUM_EMPLOYEES_TO_GENERATE):
		var candidate = {
			"id": next_employee_id,
			"name": "Candidate_" + str(next_employee_id),
			"role": "Role_" + str(next_employee_id),
			"cost": 100 + next_employee_id * 10,
			"boost": 5 + next_employee_id,
			"is_busy": false,
		}
		hire_candidates.append(candidate)
		next_employee_id += 1



#Floor Checklist

var quests = {
	"floor4": {
		"hallway1": {"desc": "Reach the end of Hallway1", "done": false},
		"room3": {"desc": "Enter Room3", "done": false},
		"room4": {"desc": "Enter Room4", "done": false},
		"room2": {"desc": "Inspect the item in Room2", "done": false},  # ✅
	},
	"floor3": {
		"hallway2": {"desc": "Reach the end of Hallway1", "done": false},
		"room1": {"desc": "Enter Room1", "done": false},
	},
	"floor5": {
		"hallway2": {"desc": "Reach the end of Hallway1", "done": false},
		"room1": {"desc": "Enter Room1", "done": false},
	}

}

var current_floor: String = ""  # Which floor is active right now

func set_floor(floor_name: String):
	current_floor = floor_name

func mark_completed(floor_name: String, quest_name: String):
	if quests.has(floor_name) and quests[floor_name].has(quest_name):
		quests[floor_name][quest_name]["done"] = true
		print("Quest completed:", quest_name, "on", floor_name)

func is_floor_complete(floor_name: String) -> bool:
	if not quests.has(floor_name):
		return false
	for quest in quests[floor_name].values():
		if not quest["done"]:
			return false
	return true

func get_floor_quests(floor_name: String) -> Dictionary:
	if quests.has(floor_name):
		return quests[floor_name]
	return {}
