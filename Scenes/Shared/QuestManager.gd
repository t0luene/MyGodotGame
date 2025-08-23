extends Node

signal requirement_completed(quest_id, req_id)
signal quest_completed(quest_id)
signal quest_updated(quest_id)

var current_quest_id: int = 0

var quests = {
	0: {
		"name": "Walk to point",
		"requirements": [{"type": "walk", "completed": false}],
		"reward_claimed": false
	},
	1: {
		"name": "Talk to boss",
		"requirements": [{"type": "talk", "completed": false}],
		"reward_claimed": false
	},
	2: {
		"name": "Visit HR",
		"requirements": [
			{"type": "exit_boss", "completed": false},
			{"type": "enter_hr", "completed": false}
		],
		"reward_claimed": false
	}
}

func complete_requirement(quest_id: int, req_id: int) -> void:
	var quest = quests[quest_id]
	quest["requirements"][req_id]["completed"] = true
	emit_signal("requirement_completed", quest_id, req_id)

	# Check if all requirements complete
	var all_done = true
	for req in quest["requirements"]:
		if not req["completed"]:
			all_done = false
			break

	if all_done:
		emit_signal("quest_completed", quest_id)
		print("QuestManager: Quest %s completed" % quest_id)

func start_quest(quest_id: int) -> void:
	current_quest_id = quest_id
	emit_signal("quest_updated", quest_id)

func start_next_quest():
	var next_id = current_quest_id + 1
	if next_id < quests.size():
		current_quest_id = next_id
		emit_signal("quest_updated", current_quest_id)

# ---------------------------
# Cross-scene helper functions
# ---------------------------
func player_exited_boss():
	complete_requirement(2, 0)  # exit boss

func player_entered_hr():
	complete_requirement(2, 1)  # entered HR
	_give_quest3_reward()

func _give_quest3_reward():
	print("Reward granted for visiting HR!")
	# Add money, XP, items, etc.
