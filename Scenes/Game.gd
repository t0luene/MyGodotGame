extends Node

# References
@onready var hud = $HUD  # If HUD is part of Game.tscn
var player: Node2D = null
var level_container: Node2D = null

func _ready():
	# Create container for levels
	level_container = Node2D.new()
	add_child(level_container)

	# Assign Player singleton
	if Engine.has_singleton("Player"):
		player = Engine.get_singleton("Player")
	else:
		push_error("⚠️ Player autoload not found!")

	# Load first scene
	call_deferred("load_boss_intro")

# --- Load BossIntro ---
func load_boss_intro() -> void:
	print("Loading BossIntro...")
	_clear_level()
	var boss_scene = load("res://Scenes/Boss/BossIntro.tscn").instantiate()
	level_container.add_child(boss_scene)
	_place_player(boss_scene)

# --- Load any floor ---
func load_floor(floor_scene_path: String) -> void:
	print("Loading floor:", floor_scene_path)
	_clear_level()
	var floor_scene = load(floor_scene_path).instantiate()
	level_container.add_child(floor_scene)
	_place_player(floor_scene)

# --- Clear level container ---
func _clear_level():
	for child in level_container.get_children():
		child.queue_free()

# --- Place player in scene at SpawnPoint ---
func _place_player(scene_node: Node):
	if not player:
		return
	if player.get_parent():
		player.get_parent().remove_child(player)
	scene_node.add_child(player)
	player.visible = true

	var spawn = scene_node.get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
		print("Player moved to SpawnPoint at:", spawn.global_position)
	else:
		push_error("SpawnPoint not found in scene: " + scene_node.name)
