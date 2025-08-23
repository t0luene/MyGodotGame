extends Control

@onready var checklist = $CanvasLayer/ChecklistUI
@onready var dialogue = $CanvasLayer/Dialogue
@onready var reward_window = $CanvasLayer/RewardWindow

var last_quest_id: int = -1  # track which quest was last displayed

func _ready():
	checklist.visible = false
	dialogue.visible = false
	reward_window.visible = false

	QuestManager.requirement_completed.connect(_on_requirement_completed)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_updated.connect(_on_quest_updated)

	# Connect dialogue finished signal
	dialogue.dialogue_finished.connect(_on_dialogue_finished)

func _on_requirement_completed(quest_id, req_id):
	checklist.update_requirement(quest_id, req_id)

func _on_quest_completed(quest_id):
	# ChecklistUI handles enabling the Finish button
	pass

func _on_quest_updated(quest_id):
	# Only rebuild checklist if the quest changed
	if quest_id == last_quest_id:
		return
	last_quest_id = quest_id
	
	# Update the checklist with the new quest
	checklist.update_quest(quest_id)
	checklist.visible = true
	
	var quest = QuestManager.quests[quest_id]
	print("DEBUG: Quest updated:", quest["name"])
	print("DEBUG: Requirements count:", quest["requirements"].size())

func claim_reward(quest_id: int) -> void:
	checklist.visible = false
	reward_window.visible = false

	var quest = QuestManager.quests[quest_id]
	quest["reward_claimed"] = true

	# Start next quest if any
	QuestManager.start_next_quest()

func _on_dialogue_finished():
	var quest_id = QuestManager.current_quest_id
	if quest_id < 0 or quest_id >= QuestManager.quests.size():
		print("DEBUG: No current quest")
		return

	var requirements = QuestManager.quests[quest_id]["requirements"]

	for i in range(requirements.size()):
		var req = requirements[i]
		if req.get("type", "") == "talk" and not req.get("completed", false):
			# Complete the requirement
			QuestManager.complete_requirement(quest_id, i)
			print("DEBUG: Completed talk requirement for quest", quest_id)
			checklist.update_requirement(quest_id, i)
			break
