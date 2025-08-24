extends Node2D

# Node references
@onready var exit_to_hallway = $ExitToHallway
@onready var spawn: Marker2D = $SpawnPoint

func _ready():
	# Reparent existing Player autoload into this scene
	if Player:
		if Player.get_parent() != self:
			if Player.get_parent():
				Player.get_parent().remove_child(Player)
			add_child(Player)
		Player.global_position = spawn.global_position
		Player.visible = true
		print("Player added to BossIntro at:", Player.global_position)
	else:
		push_error("⚠️ Player autoload missing!")

	# Connect exit trigger
	exit_to_hallway.body_entered.connect(_on_exit_to_hallway_entered)

func _on_exit_to_hallway_entered(body):
	if body != Player:
		return

	exit_to_hallway.monitoring = false  # prevent repeated triggers
	print("Exit BossIntro → Hallway0 triggered")

	# Load Hallway0 via Game autoload
	if Engine.has_singleton("Game"):
		Engine.get_singleton("Game").load_floor("res://Scenes/Rooms/Hallway0.tscn")
	else:
		push_error("⚠️ Game singleton missing — can't load Floor0")
