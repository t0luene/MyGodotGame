extends Node

# Signals
signal requirement_completed(quest_id, req_id)
signal quest_completed(quest_id)
signal quest_updated(quest_id)

# Track current active quest
var hiring_progress := {"construction": false, "hr": false}
var assignment_progress := {"hr": false, "construction": false}

var current_quest_id: int = 0

# Quest definitions
var quests = {
	0: {
		"name": "Q0 Walk to point",
		"requirements": [{"type": "walk_to_trigger", "completed": false}],
		"reward_claimed": false
	},
	1: {
		"name": "Q1 Talk to boss",
		"requirements": [{"type": "talk_to_boss", "completed": false}],
		"reward_claimed": false
	},
	2: {
		"name": "Q2 Visit HR",
		"requirements": [
			{"type": "exit_boss", "completed": false},
			{"type": "enter_hr", "completed": false}
		],
		"reward_claimed": false
	},
	3: {
		"name": "Q3 Complete HR paperwork",
		"requirements": [
			{"type": "talk_hr", "completed": false},
			{"type": "talk_to_boss", "completed": false}
		],
		"reward_claimed": false
	},
	4: {
		"name": "Q4 Maintenance Overview",
		"requirements": [
			{"type": "talk_to_boss", "completed": false},
			{"type": "exit_boss", "completed": false},
			{"type": "enter_elevator", "completed": false},
			{"type": "arrive_floor_minus1", "completed": false},
			{"type": "enter_maint_room", "completed": false},
			{"type": "talk_maint_lead", "completed": false}
		],
		"reward_claimed": false
	},
	5: {
		"id": 5,
		"name": "Q5 Grid Overview",
		"requirements": [
			{"type": "talk_to_boss", "completed": false},           # 0
			{"type": "enter_elevator", "completed": false},    # 1
			{"type": "arrive_grid_floor", "completed": false},    # 2
			{"type": "enter_grid_room", "completed": false},        # 3
			{"type": "talk_to_grid_navigator", "completed": false}, # 4
			{"type": "talk_to_boss", "completed": false}     # 5
		],
		"reward_claimed": false,
	},
	6: {
		"id": 6,
		"name": "Q6 Hiring and Assignment",
		"requirements": [
			{"type": "talk_to_boss", "completed": false},            # 0
			{"type": "talk_to_hr", "completed": false},              # 1
			{"type": "hire_employees", "completed": false},          # 2
			{"type": "unlock_department", "completed": false},       # 3
			{"type": "assign_hr", "completed": false},               # 4
			{"type": "assign_construction", "completed": false}      # 5
		],
		"reward_claimed": false
	},
	7: {
		"id": 7,
		"name": "Q7 New Day",
		"requirements": [
			{"type": "talk_to_boss", "completed": false},          # 0
			{"type": "new_day", "completed": false},          # 1
			{"type": "talk_to_boss", "completed": false},          # 2
		],
		"reward_claimed": false
		},
	8: {
		"id": 8,
		"name": "Q8 Floor Inspection & Repairs",
		"requirements": [
			{"type": "talk_to_boss", "completed": false},          # 0
			{"type": "talk_maint_lead", "completed": false},          # 1
		],
		"reward_claimed": false
		},
	9: {
		"id": 9,
		"name": "Q9 Floor1 Inspection",
		"requirements": [
			{"type": "talk_maint_lead", "completed": false},          # 0
			{"type": "enter_floor1", "completed": false},        	  # 1
			{"type": "inspect_hallway1", "completed": false},         # 2
			{"type": "inspect_elevator", "completed": false},         # 3
			{"type": "inspect_room1a", "completed": false},           # 4
			{"type": "inspect_room1b", "completed": false},           # 5
			{"type": "talk_maint_lead", "completed": false},          # 6
		],
		"reward_claimed": false
	},
	10: {
		"id": 10,
		"name": "Q10 Floor assignments",
		"requirements": [
			{"type": "talk_maint_lead", "completed": false},          # 0
			{"type": "floor1_assignment", "completed": false},        # 1
			{"type": "talk_maint_lead", "completed": false},          # 2
			{"type": "floor_management", "completed": false},         # 3
			{"type": "talk_to_boss", "completed": false},       	  # 4
		],
		"reward_claimed": false
	}
}

# ---------------------------
# Quest control
# ---------------------------
func start_quest(quest_id: int) -> void:
	current_quest_id = quest_id

	# Reset tracking for Quest6
	if quest_id == 6:
		hiring_progress = {"construction": false, "hr": false}
		assignment_progress = {"hr": false, "construction": false}

	emit_signal("quest_updated", quest_id)
	print("QuestManager: Started quest %s" % quests[quest_id]["name"])

func complete_step(step_type: String) -> void:
	if not quests.has(current_quest_id):
		return
	var reqs = quests[current_quest_id]["requirements"]
	for i in range(reqs.size()):
		var req = reqs[i]
		if req.get("type", "") == step_type:
			if req["completed"]:
				return
			complete_requirement(current_quest_id, i)
			return
	print("QuestManager: step type not found on current quest:", step_type)


func complete_requirement(quest_id: int, req_id: int) -> void:
	print("QuestManager: completing requirement ", req_id, " for quest ", quest_id)
	var quest = quests[quest_id]
	quest["requirements"][req_id]["completed"] = true
	emit_signal("requirement_completed", quest_id, req_id)
	print("QuestManager: Requirement %s of quest %s completed" % [req_id, quest["name"]])
	
	# Check if all requirements complete
	for req in quest["requirements"]:
		if not req["completed"]:
			return  # still requirements left

	emit_signal("quest_completed", quest_id)
	print("QuestManager: Quest %s completed!" % quest["name"])
	_give_reward(quest_id)

func start_next_quest():
	var next_id = current_quest_id + 1
	if next_id < quests.size():
		start_quest(next_id)

# ---------------------------
# Scene helper functions
# ---------------------------

func get_current_requirement_index() -> int:
	var reqs = quests[current_quest_id]["requirements"]
	for i in range(reqs.size()):
		if not reqs[i]["completed"]:
			return i
	return -1  # all complete



func player_walked_to_trigger():
	if current_quest_id == 0:
		complete_requirement(0, 0)

# Reuse existing function
func player_talked_to_boss():
	if current_quest_id == 1:
		complete_requirement(1, 0)
	elif current_quest_id == 3:
		complete_requirement(3, 1)
	elif current_quest_id == 4:
		complete_requirement(4, 0)
	elif current_quest_id == 5:
		if not quests[5]["requirements"][0]["completed"]:
			complete_requirement(5, 0)
		elif quests[5]["requirements"][0]["completed"] and not quests[5]["requirements"][5]["completed"]:
			complete_requirement(5, 5)
	elif current_quest_id == 6:
		complete_requirement(6, 0)
	elif current_quest_id == 7:
		if not quests[7]["requirements"][0]["completed"]:
			complete_requirement(7, 0)
		elif quests[7]["requirements"][1]["completed"] and not quests[7]["requirements"][2]["completed"]:
			complete_requirement(7, 2)
	elif current_quest_id == 8:
		complete_requirement(8, 0)
	elif current_quest_id == 10:
		# Only complete requirement 4 (talk_to_boss) if requirements 0-3 are done
		var reqs = quests[10]["requirements"]
		if reqs[0]["completed"] and reqs[1]["completed"] and reqs[2]["completed"] and reqs[3]["completed"]:
			complete_requirement(10, 4)



func player_talked_hr():
	if current_quest_id == 3:
		complete_requirement(3, 0)
	elif current_quest_id == 6:
		if not quests[6]["requirements"][1]["completed"]:
			complete_requirement(6, 1)


func player_talked_maint_lead():
	match current_quest_id:
		# ----- Quest4 -----
		4:
			complete_requirement(4, 5)

		# ----- Quest8 -----
		8:
			complete_requirement(8, 1)

		# ----- Quest9 -----
		9:
			# First talk = requirement 0
			if not quests[9]["requirements"][0]["completed"]:
				complete_requirement(9, 0)
			# Second talk = requirement 6
			elif quests[9]["requirements"][5]["completed"] and not quests[9]["requirements"][6]["completed"]:
				complete_requirement(9, 6)

		# ----- Quest10 -----
		10:
			# First talk = requirement 0
			if not quests[10]["requirements"][0]["completed"]:
				complete_requirement(10, 0)
			# Second talk = requirement 2 (after floor1 assignment is done)
			elif quests[10]["requirements"][1]["completed"] and not quests[10]["requirements"][2]["completed"]:
				complete_requirement(10, 2)




func player_exited_boss():
	if current_quest_id == 2:
		complete_requirement(2, 0)  # Quest3
	elif current_quest_id == 4:
		complete_requirement(4, 1)  # Quest5: exit_boss_for_maint


func player_entered_elevator():
	if current_quest_id == 4:
		complete_requirement(4, 2)  # Quest4: enter_elevator_maint
	elif current_quest_id == 5:
		complete_requirement(5, 1)  # Quest5: enter_elevator

		
		
func player_entered_hr():
	if current_quest_id == 2:
		complete_requirement(2, 1)


func enter_maint_room():
	complete_requirement(4, 4)  # Quest 4, requirement index 4 ("enter_maint_room")		
# ---------------------------
# Quest4 specific functions
# ---------------------------


func player_arrived_floor_minus1():
	if current_quest_id == 4:
		complete_requirement(4, 3)

func player_entered_maint_room():
	if current_quest_id == 4:
		complete_requirement(4, 4)



func player_entered_hallway_1():
	complete_requirement(QuestManager.current_quest_id, 4)  # 4 = Hallway-1


# ---------------------------
# Quest5 specific functions
# ---------------------------

func player_arrived_grid_floor():
	if current_quest_id == 5:
		complete_requirement(5, 2)  # 2 = arrive_grid_floor

func player_entered_grid_room():
	if current_quest_id == 5:
		complete_requirement(5, 3)

func player_talked_grid_navigator():
	if current_quest_id == 5:
		complete_requirement(5, 4)

func player_returned_to_boss_grid():
	if current_quest_id == 5:
		complete_requirement(5, 5)



# ---------------------------
# Quest6 specific functions
# ---------------------------

# Step 1 – talk to HR for the first time
func quest6_talked_to_hr():
	if current_quest_id == 6:
		complete_step("talk_to_hr")

# Step 2 – hiring employees
func quest6_employee_hired(role: String):
	# role is "construction" or "hr"
	if current_quest_id != 6:
		return

	if role == "construction":
		hiring_progress["construction"] = true
	elif role == "hr":
		hiring_progress["hr"] = true

	# check if both are hired
	if hiring_progress["construction"] and hiring_progress["hr"]:
		complete_step("hire_employees")

# Step 3 – HR unlocks department button
func quest6_unlocked_department():
	if current_quest_id == 6:
		complete_step("unlock_department")

# Step 4 & 5 – assigning employees
func quest6_employee_assigned(role: String):
	if current_quest_id != 6:
		return

	if role == "hr" and not assignment_progress["hr"]:
		assignment_progress["hr"] = true
		complete_step("assign_hr")
	elif role == "construction" and not assignment_progress["construction"]:
		assignment_progress["construction"] = true
		complete_step("assign_construction")


# ---------------------------
# Quest7 specific functions
# ---------------------------
func quest7_new_day():
	if current_quest_id == 7:
		complete_step("new_day")


# ---------------------------
# Quest10 specific functions
# ---------------------------

func assign_floor1_type(floor_type: String):
	# Only do if Quest10 is active
	if current_quest_id == 10:
		# Set Floor1 type in your global building_floors
		Global.building_floors[0]["type"] = floor_type
		# Mark requirement complete
		if not quests[10]["requirements"][1]["completed"]:
			complete_requirement(10, 1)
			

func open_floor_management():
	if current_quest_id == 10:
		if not quests[10]["requirements"][3]["completed"]:
			complete_requirement(10, 3)


# ---------------------------
# Rewards
# ---------------------------
func _give_reward(quest_id: int):
	var quest = quests[quest_id]
	if quest["reward_claimed"]:
		return
	quest["reward_claimed"] = true
	print("Reward granted for quest: %s" % quest["name"])
	# TODO: add XP, money, items, etc.
