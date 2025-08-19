extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var exit_to_hallway: Area2D = $ExitToHallway  # doorway back to Hallway1

func _ready():
	# Mark Room4 quest done immediately upon entering
	Global.mark_completed("floor3", "room1")

	# Connect the exit trigger
	exit_to_hallway.body_entered.connect(_on_exit_entered)

	# Fade in
	Fade.fade_in(0.5)

# Handler for exit trigger
func _on_exit_entered(body) -> void:
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Tell Floor4 to load Hallway1
	get_parent().get_parent().load_room("Scenes/Rooms/Hallway2.tscn")
