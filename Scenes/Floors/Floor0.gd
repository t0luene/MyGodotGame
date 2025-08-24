extends Node2D

@onready var spawn = $SpawnPoint

func _ready():
	# Add Player if not already in scene
	if Player:
		if Player.get_parent() != self:
			if Player.get_parent():
				Player.get_parent().remove_child(Player)
			add_child(Player)
		Player.global_position = spawn.global_position
		Player.visible = true
	else:
		push_error("⚠️ Player autoload not found!")
