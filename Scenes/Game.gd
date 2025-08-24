extends Node

var player: Node2D = null
var current_scene: Node = null

func _ready():
	print("Game ready, spawning player")

	# Spawn Player once if not already
	if not player:
		var player_scene = load("res://Player.tscn")
		player = player_scene.instantiate()
		add_child(player)
		player.visible = true

	load_boss_intro()

# --- Load BossIntro ---
func load_boss_intro():
	if current_scene:
		current_scene.queue_free()

	current_scene = load("res://Scenes/Boss/BossIntro.tscn").instantiate()
	add_child(current_scene)

	# Move player to spawn
	var spawn = current_scene.get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
	print("Loaded scene: BossIntro, Player at:", player.global_position)

# --- Load Hallway0 ---
func load_hallway():
	if current_scene:
		current_scene.queue_free()

	current_scene = load("res://Scenes/Rooms/Hallway0.tscn").instantiate()
	add_child(current_scene)

	# Move player to spawn
	var spawn = current_scene.get_node_or_null("PlayerSpawn")
	if spawn:
		player.global_position = spawn.global_position
	print("Loaded scene: Hallway0, Player at:", player.global_position)
