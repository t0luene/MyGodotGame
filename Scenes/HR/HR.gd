extends Node2D

func _ready():
	# Move Player into this scene
	if Player.get_parent() != self:
		if Player.get_parent():
			Player.get_parent().remove_child(Player)
		add_child(Player)

	Player.visible = true
	# Place Player at scene spawn if exists
	var spawn = get_node_or_null("PlayerSpawn")
	if spawn:
		Player.global_position = spawn.global_position

	# Mark quest step complete
	QuestManager.player_entered_hr()
	print("Quest step completed: entered HR")
