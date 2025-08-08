extends Area2D

@export var room_name = "Room"

signal inspected(name: String)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("BODY ENTERED:", body.name)
	if body.is_in_group("player"):
		print("Player entered", room_name)
		emit_signal("inspected", room_name)
