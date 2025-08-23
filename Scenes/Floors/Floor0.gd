extends Node2D

@onready var scene_container = $SceneContainer
@onready var player_spawn: Marker2D = $PlayerSpawn
var current_room: Node = null

func _ready():
	print("Floor0 ready")
	load_room("res://Scenes/Rooms/Hallway0.tscn")

func load_room(path: String):
	# Remove previous room
	if current_room and current_room.is_inside_tree():
		current_room.queue_free()

	# Load new room
	var room_scene: PackedScene = load(path)
	current_room = room_scene.instantiate()
	scene_container.add_child(current_room)
	print("Loaded room:", path)
	await get_tree().process_frame  # ensure room is in tree

	# Player debug
	if Engine.has_singleton("Player"):
		var player = Engine.get_singleton("Player")
		if player.get_parent() != current_room:
			if player.get_parent():
				player.get_parent().remove_child(player)
			current_room.add_child(player)
		player.visible = true

		var spawn = current_room.get_node_or_null("SpawnPoint")
		if spawn:
			player.global_position = spawn.global_position
			print("Player moved to room SpawnPoint:", spawn.global_position)
		else:
			player.global_position = player_spawn.global_position
			print("Player moved to floor SpawnPoint:", player.global_position)
	else:
		push_error("Player singleton not found!")
