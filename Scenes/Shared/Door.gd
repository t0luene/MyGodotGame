extends Area2D

signal pressed

func _ready():
	print("✅ Door ready:", name)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("🚶 Body entered door:", body.name)
	if body.name == "Player":
		print("🔔 Door pressed signal emitted!")
		emit_signal("pressed")
