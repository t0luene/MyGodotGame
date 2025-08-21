extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var exit_to_hallway: Area2D = $ExitToHallway  # doorway back to Hallway-1

func _ready():
	# Fade in
	Fade.fade_in(0.5)

	# Connect the exit trigger
	exit_to_hallway.body_entered.connect(_on_exit_entered)

	# Ensure Dialogue node exists and is in group "Dialogue"
	var dialogue_node = $Dialogue
	if dialogue_node:
		dialogue_node.add_to_group("Dialogue")
		dialogue_node.visible = false

# Handler for exit trigger
func _on_exit_entered(body) -> void:
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Tell Floor-1 to load Hallway-1
	get_parent().get_parent().load_room("Scenes/Rooms/Hallway-1.tscn")
