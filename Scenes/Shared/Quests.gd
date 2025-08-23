# Quests.gd
extends Node

# =====================
# QUEST DATA
# =====================
# Each floor contains quests with description, done status, rewards, and reward_claimed flag
var quests = {
	"floor-1": {
		"hallway-1": {"desc": "Explore the hallway", "done": false, "xp": 10, "hearts": 1, "energy": 1, "reward_claimed": false},
		"maintenance_room": {"desc": "Enter the Maintenance room", "done": false, "xp": 5, "hearts": 0, "energy": 0, "reward_claimed": false},
		"talk_to_crew": {"desc": "Talk to all maintenance crew", "done": false, "xp": 15, "hearts": 1, "energy": 2, "reward_claimed": false}
	},
	"floor0": {
		"hallway0": {"desc": "Leave boss's office and go into Hallway0", "done": false, "xp": 5, "hearts": 0, "energy": 0, "reward_claimed": false},
		"hr": {"desc": "Enter HR room", "done": false, "xp": 5, "hearts": 0, "energy": 0, "reward_claimed": false},
		"talk_to_hr": {"desc": "Talk to HR lady", "done": false, "xp": 10, "hearts": 1, "energy": 1, "reward_claimed": false},
		"hired": {"desc": "Get congratulated by the boss", "done": false, "xp": 50, "hearts": 2, "energy": 5, "reward_claimed": false}
	},
	"floor3": {
		"hallway2": {"desc": "Reach the end of Hallway1", "done": false, "xp": 10, "hearts": 1, "energy": 1, "reward_claimed": false},
		"room1": {"desc": "Enter Room1", "done": false, "xp": 5, "hearts": 1, "energy": 0, "reward_claimed": false}
	},
	"floor4": {
		"hallway1": {"desc": "Reach the end of Hallway1", "done": false, "xp": 10, "hearts": 1, "energy": 1, "reward_claimed": false},
		"room3": {"desc": "Enter Room3", "done": false, "xp": 5, "hearts": 1, "energy": 0, "reward_claimed": false},
		"room4": {"desc": "Enter Room4", "done": false, "xp": 5, "hearts": 1, "energy": 0, "reward_claimed": false},
		"room2": {"desc": "Inspect the item in Room2", "done": false, "xp": 15, "hearts": 2, "energy": 2, "reward_claimed": false}
	},
	"floor5": {
		"hallway2": {"desc": "Reach the end of Hallway1", "done": false, "xp": 10, "hearts": 1, "energy": 1, "reward_claimed": false},
		"room1": {"desc": "Enter Room1", "done": false, "xp": 5, "hearts": 1, "energy": 0, "reward_claimed": false}
	}
}

# =====================
# HELPER METHODS
# =====================

# Returns the list of quest names for a floor
func get_floor_quests(floor_name: String) -> Array:
	if quests.has(floor_name):
		return quests[floor_name].keys()
	return []

# Returns true if all quests on a floor are done
func is_floor_complete(floor_name: String) -> bool:
	if not quests.has(floor_name):
		return false
	for quest_name in quests[floor_name].keys():
		if not quests[floor_name][quest_name]["done"]:
			return false
	return true

# Returns the rewards for the first done quest that hasn't been claimed yet
func get_current_rewards(floor_name: String) -> Dictionary:
	if not quests.has(floor_name):
		return {"xp": 0, "hearts": 0, "energy": 0}
	for quest_name in quests[floor_name].keys():
		var q = quests[floor_name][quest_name]
		if q["done"] and not q.get("reward_claimed", false):
			return {
				"xp": q.get("xp", 0),
				"hearts": q.get("hearts", 0),
				"energy": q.get("energy", 0)
			}
	return {"xp": 0, "hearts": 0, "energy": 0}

# Mark a quest as done
func mark_quest_done(floor_name: String, quest_name: String) -> void:
	if quests.has(floor_name) and quests[floor_name].has(quest_name):
		quests[floor_name][quest_name]["done"] = true

# Mark a quest reward as claimed
func mark_reward_claimed(floor_name: String, quest_name: String) -> void:
	if quests.has(floor_name) and quests[floor_name].has(quest_name):
		quests[floor_name][quest_name]["reward_claimed"] = true


var current_floor: String = ""          # Which floor is active right now
var current_floor_scene: String = ""    # e.g. "res://Scenes/Floors/BossRoom.tscn"

func set_floor(floor_name: String):
	current_floor = floor_name
