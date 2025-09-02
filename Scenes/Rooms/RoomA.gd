extends Node2D

@export var room_id: String = ""

@onready var player: CharacterBody2D = $Player
@onready var exit_to_hallway: Area2D = $ExitToHallway

func _ready():
	print("✅ Room ready:", name, "Instance ID:", get_instance_id(), "Room ID:", room_id)

	if QuestManager.current_quest_id == 9:
		QuestManager.complete_requirement(9, 4)
		print("✅ Quest 2 Task 'enter_hr' complete")

	if exit_to_hallway:
		exit_to_hallway.body_entered.connect(_on_exit_entered)

	#Fade.fade_in(0.5)

func _on_exit_entered(body):
	if body.name != "Player":
		return

	print("🚶 Player exited room -> going back to hallway")

	#Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	var hallway_scene = load("res://Scenes/Shared/Hallway.tscn")
	if not hallway_scene:
		push_error("❌ Failed to load hallway")
		return

	get_tree().change_scene_to_packed(hallway_scene)
