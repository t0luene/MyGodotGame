extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var entrance_area: Area2D = $Entrance1  # doorway to Floor3

func _ready():
	entrance_area.body_entered.connect(_on_entrance_entered)
	
	# Fade in when the scene starts
	Fade.fade_in(0.5)

func _on_entrance_entered(body):
	if body.name != "Player":
		return

	# Fade out, wait, then switch scene
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Floor3.tscn")
