extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var room_triggers = $RoomTriggers
@onready var rooms = $Rooms  # Container node holding your room fog overlays (ColorRects, Sprites, etc)
@onready var fog_map = $FogMap  # Adjust path if needed
@onready var ghosts = $Ghosts
@onready var black_fade = $Camera2D/UI/BlackFade  # Adjust path to your fade UI node
@onready var spooked_text = $Camera2D/UI/SpookedText  # Your Label or RichTextLabel for message

func _ready():
	black_fade.visible = false
	spooked_text.visible = false

	for ghost in ghosts.get_children():
		ghost.connect("player_spooked", Callable(self, "_on_ghost_player_spooked"))
	
	player.allow_vertical_movement = true
	camera.make_current()

	for trigger in room_triggers.get_children():
		trigger.body_entered.connect(_make_body_entered_callback(trigger))
		trigger.body_exited.connect(_make_body_exited_callback(trigger))

func _on_ghost_player_spooked():
	# Stop player movement immediately
	if player.has_method("set_velocity"):
		player.set_velocity(Vector2.ZERO) # For CharacterBody2D using move_and_slide
	elif "velocity" in player:
		player.velocity = Vector2.ZERO

	# Disable inspecting or other input if needed
	Global.can_inspect = false


func _make_body_entered_callback(trigger):
	return func(body):
		_on_room_trigger_body_entered(body, trigger)

func _make_body_exited_callback(trigger):
	return func(body):
		_on_room_trigger_body_exited(body, trigger)

func _on_room_trigger_body_entered(body, trigger):
	if body != player:
		return

	var fog_name = trigger.name.replace("_Trigger", "_Fog")
	var room_fog = rooms.get_node_or_null(fog_name)
	if room_fog:
		room_fog.visible = false
	else:
		print("Warning: No fog overlay named ", fog_name)

func _on_room_trigger_body_exited(body, trigger):
	if body != player:
		return

	var fog_name = trigger.name.replace("_Trigger", "_Fog")
	var room_fog = rooms.get_node_or_null(fog_name)
	if room_fog:
		room_fog.visible = true

func _process(delta):
	camera.position = player.position
	clear_fog_around_player()

func clear_fog_around_player(radius = 10):
	var local_pos = fog_map.to_local(player.global_position)
	var player_cell = fog_map.local_to_map(local_pos)
	
	for x in range(player_cell.x - radius, player_cell.x + radius + 1):
		for y in range(player_cell.y - radius, player_cell.y + radius + 1):
			var cell_pos = Vector2i(x, y)
			if player_cell.distance_to(cell_pos) <= radius:
				fog_map.set_cell(0, cell_pos, -1)
