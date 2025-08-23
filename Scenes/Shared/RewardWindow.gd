extends Control

@onready var reward_label = $Panel/Label       # main reward text
@onready var xp_label = $Panel/XPLabel
@onready var hearts_label = $Panel/HeartsLabel
@onready var energy_label = $Panel/EnergyLabel
@onready var close_button = $Panel/CloseButton

func _ready():
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	else:
		push_error("CloseButton not found under Panel in RewardWindow")

func show_reward(quest_id: int) -> void:
	var quest = QuestManager.quests[quest_id]
	
	reward_label.text = "Reward: " + str(quest.get("reward", "???"))
	xp_label.text = "XP: " + str(quest.get("xp", 0))
	hearts_label.text = "Hearts: " + str(quest.get("hearts", 0))
	energy_label.text = "Energy: " + str(quest.get("energy", 0))
	
	visible = true

func hide_reward() -> void:
	visible = false

func _on_close_pressed() -> void:
	hide_reward()
	HUD.claim_reward(QuestManager.current_quest_id)
