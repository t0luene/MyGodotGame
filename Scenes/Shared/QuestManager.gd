extends Node

# Signals
signal requirement_completed(quest_id, req_id)
signal quest_completed(quest_id)
signal quest_updated(quest_id)

# Track current active quest
var current_quest_id: int = 0

# Quest definitions
var quests = {
	0: {
		"name": "Walk to point",
		"requirements": [{"type": "walk_to_trigger", "completed": false}],
		"reward_claimed": false
	},
	1: {
		"name": "Talk to boss",
		"requirements": [{"type": "talk_to_boss", "completed": false}],
		"reward_claimed": false
	},
	2: {
		"name": "Visit HR",
		"requirements": [
			{"type": "exit_boss", "completed": false},
			{"type": "enter_hr", "completed": false}
		],
		"reward_claimed": false
	},
	3: {
		"name": "Complete HR paperwork",
		"requirements": [
			{"type": "talk_hr", "completed": false},
			{"type": "talk_boss_fulltime", "completed": false}
		],
		"reward_claimed": false
	},
	4: {
		"name": "Assist Maintenance",
		"requirements": [
			{"type": "talk_to_boss_maint", "completed": false},
			{"type": "exit_boss_for_maint", "completed": false},
			{"type": "enter_elevator_maint", "completed": false},
			{"type": "arrive_floor_minus1", "completed": false},
			{"type": "enter_maint_room", "completed": false},
			{"type": "talk_maint_lead", "completed": false}
		],
		"reward_claimed": false
	}
}

# ---------------------------
# Quest control
# ---------------------------
func start_quest(quest_id: int) -> void:
	current_quest_id = quest_id
	emit_signal("quest_updated", quest_id)
	print("QuestManager: Started quest %s" % quests[quest_id]["name"])

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

func player_walked_to_trigger():
	if current_quest_id == 0:
		complete_requirement(0, 0)

# Reuse existing function
func player_talked_to_boss():
	if current_quest_id == 1:
		complete_requirement(1, 0)  # Quest2
	elif current_quest_id == 4:
		complete_requirement(4, 0)  # Quest5: talk_to_boss_maint

# Reuse existing function
func player_exited_boss():
	if current_quest_id == 2:
		complete_requirement(2, 0)  # Quest3
	elif current_quest_id == 4:
		complete_requirement(4, 1)  # Quest5: exit_boss_for_maint

func player_entered_hr():
	if current_quest_id == 2:
		complete_requirement(2, 1)

func player_talked_hr():
	if current_quest_id == 3:
		complete_requirement(3, 0)

func player_talked_boss_fulltime():
	if current_quest_id == 3:
		complete_requirement(3, 1)

func enter_maint_room():
	complete_requirement(4, 4)  # Quest 4, requirement index 4 ("enter_maint_room")

# ---------------------------
# Quest5 specific functions
# ---------------------------
func player_entered_elevator_maint():
	if current_quest_id == 4:
		complete_requirement(4, 2)

func player_arrived_floor_minus1():
	if current_quest_id == 4:
		complete_requirement(4, 3)

func player_entered_maint_room():
	if current_quest_id == 4:
		complete_requirement(4, 4)

func player_talked_maint_lead():
	if current_quest_id == 4:
		complete_requirement(4, 5)

func player_entered_hallway_1():
	complete_requirement(QuestManager.current_quest_id, 4)  # 4 = Hallway-1


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
