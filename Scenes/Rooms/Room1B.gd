extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var exit_to_hallway: Area2D = $ExitToHallway

func _ready():
	if QuestManager.current_quest_id == 9:
		# Task 1 = enter_hr
		QuestManager.complete_requirement(9, 5)
		print("✅ Quest 2 Task 'enter_hr' complete")
	exit_to_hallway.body_entered.connect(_on_exit_entered)
	Fade.fade_in(0.5)


func _on_exit_entered(body):
	if body.name != "Player":
		return
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_parent().get_parent().load_room("Scenes/Rooms/Hallway1.tscn")
