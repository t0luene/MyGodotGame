extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var exit_area: Area2D = $ExitToHallway  # doorway back to Hallway1

func _ready():
	exit_area.body_entered.connect(_on_exit_entered)

	# Fade in when the scene starts
	Fade.fade_in(0.5)

func _on_exit_entered(body):
	if body.name != "Player":
		return

	# Fade out, wait, then switch scene
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Hallway1.tscn")
