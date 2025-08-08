extends Area2D

var player_inside := false

func _on_body_entered(body):
	if body.name == "player":
		player_inside = true

func _on_body_exited(body):
	if body.name == "player":
		player_inside = false

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("ui_accept"):
		unlock_floor()


func unlock_floor():
	if "Training Floor 1" not in Global.unlocked_floors:
		Global.unlocked_floors.append("Training Floor 1")
		print("✅ Floor Unlocked!")
		queue_free()  # Optional: remove the unlock zone after use
