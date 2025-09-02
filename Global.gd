# Global.gd
extends Node

# --------------------------- Signals ⚡ ---------------------------
signal mission_status_changed(mission_name: String)
signal employee_returned(employee_id: int)
signal money_changed(new_money: int)
signal energy_changed(new_energy: int) 
signal floor_state_changed(floor_index: int)

# --------------------------- Preloads 📦 ---------------------------
const Employee = preload("res://Scenes/Shared/Employee.gd")
const EmployeeGenerator = preload("res://Scenes/Globals/EmployeeGenerator.gd")

# --------------------------- Player / Business State 💰🪫 ---------------------------
var money: int = 200
var energy: int = 5
var stress: int = 0
var reputation: int = 0
var day: int = 1
var employee_capacity: int = 3
var grid_xp: int = 0
var can_inspect: bool = true

func set_money(value: int):
	money = value
	emit_signal("money_changed", money)

func add_energy(amount: int):
	energy += amount
	emit_signal("energy_changed", energy)

func spend_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		emit_signal("energy_changed", energy)
		return true
	return false

func add_daily_money():
	set_money(money + 10)

func refresh_energy():
	energy = 5  # or Global.max_energy if you define it
	emit_signal("energy_changed", energy)

func add_grid_xp(amount: int):
	grid_xp += amount
	print("Grid XP is now:", grid_xp)

# --------------------------- Employees 💪 ---------------------------
var hired_employees: Array = []
var hire_candidates: Array = []
var next_employee_id: int = 0
var hire_candidates_day: int = -1
const NUM_EMPLOYEES_TO_GENERATE = 2  # candidates per day (excluding Day 1 fixed)

# ---- Candidate Generation 🧑‍💼 ----
func get_hire_candidates(force_new: bool = false) -> Array:
	if hire_candidates.is_empty() or hire_candidates_day != day or force_new:
		generate_hire_candidates()
		hire_candidates_day = day
	return hire_candidates

func refresh_hire_candidates() -> Array:
	print("=== Refresh called ===")
	hire_candidates.clear()
	var capacity = get_hiring_capacity()
	var new_list: Array = []

	var generator = EmployeeGenerator.new()
	generator.used_combinations.clear()

	for i in range(capacity):
		var emp = generator.generate_employee(next_employee_id)
		next_employee_id += 1
		new_list.append(emp)

	hire_candidates = new_list
	hire_candidates_day = day
	print("=== Refresh finished ===")
	return hire_candidates

func refresh_hire_candidates_by_role(role: String) -> Array:
	hire_candidates.clear()
	var capacity = get_hiring_capacity()
	var new_list: Array = []

	var generator = EmployeeGenerator.new()
	generator.used_combinations.clear()

	for i in range(capacity):
		var emp = generator.generate_employee(next_employee_id)
		next_employee_id += 1
		emp.role = role
		new_list.append(emp)

	hire_candidates = new_list
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
		var total_slots = get_hiring_capacity()
		var generated = 0
		while generated < total_slots:
			var new_emp = generator.generate_employee(next_employee_id)
			next_employee_id += 1

			var duplicate = false
			for emp in hired_employees:
				if emp.name == new_emp.name and emp.role == new_emp.role and new_emp.bio.find(emp.bio.split("\n")[0]) != -1:
					duplicate = true
					break
			if duplicate:
				continue

			hire_candidates.append(new_emp)
			generated += 1

# ---- Employee Utilities 🔧 ----
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

# --------------------------- Floors 🏢 ---------------------------
var current_floor_scene: String = ""
var building_floors: Array = []
enum FloorState { LOCKED, AVAILABLE, READY, ASSIGNED }
var next_room_to_load: String = ""
var current_inspection_floor: int = -1
var persistent_hallways: Dictionary = {}  # floor_index -> Hallway instance
var persistent_rooms: Dictionary = {}     # room_id -> Room instance

# --- Initialize Floors with Permanent Room IDs ---
func initialize_floor_ids():
	while building_floors.size() < 13:
		building_floors.append({})

	for floor_index in range(0, 13):
		var floor = building_floors[floor_index]

		if not floor.has("floor_id"):
			floor["floor_id"] = "floor_%d" % floor_index

		# Only add 1 default room if none exist
		if not floor.has("rooms") or floor["rooms"].size() == 0:
			var room_id = "%s_room_1" % floor["floor_id"]
			floor["rooms"] = [{
				"id": room_id,
				"scene": "res://Scenes/Rooms/RoomA.tscn",
				"row": 0,
				"col": 0
			}]
			floor["room_ids"] = [room_id]
			floor["next_room_num"] = 2

		building_floors[floor_index] = floor


# --- Add a New Room to a Floor ---
func add_room_to_floor(floor_index: int, scene_path: String, row: int, col: int):
	if floor_index < 0 or floor_index >= building_floors.size():
		push_error("Invalid floor_index in add_room_to_floor: %d" % floor_index)
		return

	var floor = building_floors[floor_index]

	if not floor.has("floor_id"):
		floor["floor_id"] = "floor_%d" % floor_index

	if not floor.has("rooms"):
		floor["rooms"] = []

	if not floor.has("room_ids"):
		floor["room_ids"] = []

	if not floor.has("next_room_num"):
		floor["next_room_num"] = floor["rooms"].size() + 1

	var next_room_num = floor["next_room_num"]
	var room_id = "%s_room_%d" % [floor["floor_id"], next_room_num]
	floor["next_room_num"] = next_room_num + 1

	var room_data = {
		"id": room_id,
		"scene": scene_path,
		"row": row,
		"col": col
	}

	floor["rooms"].append(room_data)
	floor["room_ids"].append(room_id)

	building_floors[floor_index] = floor

	print("🟢 Added room to Floor %d with ID %s at row %d, col %d. Total rooms now: %d" %
		  [floor_index + 1, room_id, row, col, floor["rooms"].size()])


#-------------------

	
func _unlock_floor(floor_index: int) -> void:
	if floor_index < 0 or floor_index >= building_floors.size():
		push_error("Invalid floor index: %s" % floor_index)
		return
	
	var floor = building_floors[floor_index]
	if floor.get("unlocked", false):
		print("⚠️ Floor %s already unlocked" % floor_index)
		return
	
	# Mark floor unlocked
	floor["unlocked"] = true
	floor["type"] = "inspection"
	
	# Ensure floor has at least one room
	if not floor.has("rooms") or floor["rooms"].is_empty():
		var room_id = "floor%s_room1" % floor_index
		floor["rooms"] = [
			{"id": room_id, "scene": "res://Scenes/Rooms/RoomA.tscn"}
		]
		print("🆕 Added default room %s to floor %s" % [room_id, floor_index])
	
	# Save back to building_floors
	building_floors[floor_index] = floor
	
	print("✅ Floor %s unlocked" % floor_index)


func set_floor_state(floor_index: int, new_state: int):
	if floor_index < 0 or floor_index >= building_floors.size():
		push_error("Invalid floor index in set_floor_state: %d" % floor_index)
		return
	building_floors[floor_index]["state"] = new_state
	emit_signal("floor_state_changed", floor_index)

# Global.gd
func ensure_building_floors_initialized():
	if building_floors.size() == 0:
		init_building_floors(13)  # your total floor count

	# Ensure every floor has at least 1 default room
	for i in range(building_floors.size()):
		var floor = building_floors[i]
		if not floor.has("rooms") or floor["rooms"].size() == 0:
			# Initialize rooms array with default room
			floor["rooms"] = [{
				"id": "floor_%d_room_1" % i,
				"scene": "res://Scenes/Rooms/RoomA.tscn",
				"row": 0,
				"col": 0
			}]
			# Initialize room_ids
			floor["room_ids"] = ["floor_%d_room_1" % i]
			# Ensure floor_id exists
			if not floor.has("floor_id"):
				floor["floor_id"] = "floor_%d" % i
		building_floors[i] = floor


func set_floor(floor_name: String):
	current_floor_scene = floor_name
	print("Global: current floor set to ", floor_name)

func init_building_floors(count: int = 13):
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
				state_val = FloorState.AVAILABLE
			1:
				scene_path = "res://Scenes/Floors/Floor2.tscn"
				label_text = "Floor 2"
			_:
				scene_path = "res://Scenes/Floors/Floor%d.tscn" % (i + 1)
				label_text = "Floor %d" % (i + 1)

		var floor := {
			"scene": scene_path,
			"label": label_text,
			"state": state_val,
			"purpose": "",
			"capacity": 3,
			"assigned_employee_indices": []
		}
		for j in range(floor["capacity"]):
			floor["assigned_employee_indices"].append(null)

		building_floors.append(floor)

# --------------------------- Hiring Capacity 🧾 ---------------------------
var hiring_window: Window = null
var base_hiring_capacity: int = 2
var extra_hiring_capacity: int = 0

func get_hiring_capacity() -> int:
	return base_hiring_capacity + extra_hiring_capacity

func get_hired_count() -> int:
	return hired_employees.size()

func can_hire_more() -> bool:
	return get_hired_count() < get_hiring_capacity()

# --------------------------- Tech Tree 🌳 ---------------------------
var unlocked_nodes: Dictionary = {}
var btp: int = 5  # tech points

func is_node_unlocked(node_name: String) -> bool:
	return unlocked_nodes.has(node_name)

# --------------------------- Missions 🎯 ---------------------------
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

# --------------------------- Miscellaneous 🔧 ---------------------------
func clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()

# --------------------------- HR 🏢 ---------------------------
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

# --------------------------- Maintenance 🛠️ ---------------------------
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
