extends Control

@onready var quest_label: Label = $VBoxContainer/QuestLabel
@onready var requirements_list: VBoxContainer = $VBoxContainer/RequirementsList
@onready var finish_button: Button = $VBoxContainer/FinishButton

var current_quest_id: int = -1

func _ready():
	finish_button.disabled = true
	finish_button.pressed.connect(_on_finish_pressed)
	visible = false

func update_quest(quest_id: int) -> void:
	current_quest_id = quest_id
	visible = true
	finish_button.disabled = true

	var quest = QuestManager.quests[quest_id]
	quest_label.text = quest["name"]

	# Clear old requirements
	for child in requirements_list.get_children():
		child.queue_free()

	# Add new requirements with unique names
	for i in range(quest["requirements"].size()):
		var req = quest["requirements"][i]
		var lbl = Label.new()
		lbl.text = "- " + req["type"].capitalize()
		lbl.name = str(quest_id) + "_" + str(i)  # unique per quest + requirement
		requirements_list.add_child(lbl)

func update_requirement(quest_id: int, req_id: int) -> void:
	var lbl_name = str(quest_id) + "_" + str(req_id)
	var lbl = requirements_list.get_node_or_null(lbl_name)
	if lbl:
		lbl.text = lbl.text + " ✅"
		lbl.add_theme_color_override("font_color", Color(0, 1, 0))  # green
		print("DEBUG: Added ✅ for req", req_id, "in quest", quest_id)
	else:
		print("DEBUG: Label not found for req_id", req_id)

	# Enable finish button if all requirements complete
	if are_all_requirements_complete(quest_id):
		finish_button.disabled = false

func are_all_requirements_complete(quest_id: int) -> bool:
	var quest = QuestManager.quests[quest_id]
	for req in quest["requirements"]:
		if not req["completed"]:
			return false
	return true

func _on_finish_pressed() -> void:
	var reward_window = get_node("../RewardWindow")  # relative to CheckListUI
	reward_window.visible = true

	finish_button.disabled = true

	var quest = QuestManager.quests[current_quest_id]
	quest["reward_claimed"] = true
