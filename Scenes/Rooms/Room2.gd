extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var exit_to_hallway: Area2D = $ExitToHallway
@onready var box = $Box

func _ready():
	# Hook up exit trigger
	exit_to_hallway.body_entered.connect(_on_exit_entered)

	# Hook up box inspection
	box.inspected.connect(_on_box_inspected)

	# Fade in
	Fade.fade_in(0.5)

# Exit handler
func _on_exit_entered(body):
	if body.name != "Player":
		return

	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Correct parent chain to call Floor4.load_room()
	var floor4 = get_parent().get_parent()
	if floor4 and floor4.has_method("load_room"):
		floor4.load_room("Scenes/Rooms/Hallway1.tscn")
	else:
		print("⚠️ Room2 not under Floor4 — cannot exit correctly")


# Box inspection handler
func _on_box_inspected(_box):
	# Mark the Room2 quest complete in Global
	Global.mark_completed("floor4", "room2")
	print("Room2 objective complete!")
