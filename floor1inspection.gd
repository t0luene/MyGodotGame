extends Node2D

var total_rooms := 0
var visited_rooms := 0
var visited_flags := {}

@onready var rps_popup = $RPSPopup
@onready var unlock_button := $UI/UnlockButton
@onready var progress_label := $UI/Floor1
@onready var dialogue_panel = $UI/DialoguePanel
@onready var dialogue_label = $UI/DialoguePanel/DialogueLabel
@export var inspected_floor_index: int = -1

signal inspection_complete(floor_index: int)

@onready var fog_opaque: TileMap = $FogOpaqueTileMap
@onready var fog_faded: TileMap = $FogFadedTileMap
@onready var player: CharacterBody2D = $Player
@export var clear_radius: int = 2  # You can keep or remove if unused
@export var visible_radius: int = 2  # Tiles fully cleared around player
@export var explored_radius: int = 4 # Tiles with faded fog beyond visible

var fog_states := {}

func _ready():
	initialize_fog()
	print("Testing signal manually...")
	print("🔍 UnlockButton signals:", unlock_button.get_signal_connection_list("pressed"))

	unlock_button.visible = false
	progress_label.text = "Rooms Inspected: 0 / 0"
	total_rooms = 0
	visited_flags.clear()

	for room in $RoomAreas.get_children():
		if not room.has_signal("inspected"):
			print("❌ Skipping room, no signal: ", room.name)
			continue

		var room_id = room.room_name
		visited_flags[room_id] = false
		total_rooms += 1

		room.inspected.connect(_on_room_inspected)
		print("✅ Connected to room:", room_id)

	progress_label.text = "Rooms Inspected: %d / %d" % [visited_rooms, total_rooms]

	for interactable in $Interactables.get_children():
		if interactable.has_signal("picked_up"):
			interactable.picked_up.connect(_on_item_picked_up)
		if interactable.has_signal("interacted"):
			interactable.interacted.connect(_on_ghost_interacted)
		if interactable.has_signal("talked_to"):
			interactable.talked_to.connect(_on_ghost_talked_to)

	if rps_popup and rps_popup.has_signal("rps_result"):
		rps_popup.connect("rps_result", Callable(self, "_on_rps_result"))
		print("✅ rps_result signal connected")
	else:
		print("❌ ERROR: RPSPopup not found or missing rps_result signal")

	var player_node = get_node_or_null("Player")
	if not player_node:
		print("Player node not found")
		return

	player.allow_vertical_movement = true

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		print("Camera node class:", camera.get_class())
		camera.make_current()
		print("Camera activated for inspection.")
	else:
		print("Camera2D node not found under Player")

func _process(_delta: float) -> void:
	update_fog()

func initialize_fog():
	if fog_opaque == null or fog_faded == null:
		print("⚠ Fog layers not present in this scene, skipping fog setup")
		return

	# Initialize all fog tiles as unexplored and clear faded fog tiles
	fog_states.clear()
	for cell in fog_opaque.get_used_cells(0):
		fog_states[cell] = 0
		fog_faded.set_cell(0, cell, -1)

func reveal_area(world_position: Vector2, radius: int = 3):
	if fog_opaque == null or fog_faded == null:
		return  # no fog on this map, nothing to do

	var center = fog_opaque.local_to_map(world_position)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var cell = center + Vector2i(x, y)
			if fog_states.has(cell) and fog_states[cell] == 0:
				fog_states[cell] = 1
				fog_opaque.set_cell(0, cell, -1)  # clear opaque fog
				fog_faded.set_cell(0, cell, 0)   # faded fog tile


func update_fog():
	if fog_opaque == null or fog_faded == null:
		return  # No fog layers on this map, skip

	var player_tile = fog_opaque.local_to_map(player.global_position)

	for tile_pos in fog_states.keys():
		var dist = player_tile.distance_to(tile_pos)

		if dist <= visible_radius:
			if fog_states[tile_pos] != 2:
				fog_states[tile_pos] = 2
				fog_opaque.set_cell(0, tile_pos, -1)
				fog_faded.set_cell(0, tile_pos, -1)

		elif dist <= explored_radius:
			if fog_states[tile_pos] != 1:
				fog_states[tile_pos] = 1
				fog_opaque.set_cell(0, tile_pos, -1)
				fog_faded.set_cell(0, tile_pos, tile_faded_tile_id())

		else:
			if fog_states[tile_pos] != 0:
				fog_states[tile_pos] = 0
				fog_opaque.set_cell(0, tile_pos, tile_opaque_tile_id())
				fog_faded.set_cell(0, tile_pos, -1)

	if not 0 in fog_states.values():
		print("✅ All fog explored!")
		emit_signal("inspection_complete", 0)


func tile_opaque_tile_id() -> int:
	# Change if your opaque fog tile ID is different
	return 0

func tile_faded_tile_id() -> int:
	# Change if your faded fog tile ID is different
	return 0

func _on_ghost_talked_to(ghost_name: String, dialogue: String) -> void:
	dialogue_label.text = "%s says:\n%s" % [ghost_name, dialogue]
	dialogue_panel.visible = true

	if ghost_name == "Battle Ghost":
		var ghost = $Interactables.get_node_or_null(ghost_name)
		if ghost:
			show_rps(ghost_name)
	else:
		await get_tree().create_timer(2.0).timeout
		var ghost = $Interactables.get_node_or_null(ghost_name)
		if ghost:
			ghost.queue_free()
		dialogue_panel.visible = false

func handle_rps_result(success: bool, ghost: Node) -> void:
	if success:
		print("🎉 Beat the ghost!")
		dialogue_label.text = "%s: Hmph... you win..." % ghost.name
		dialogue_panel.visible = true
		await get_tree().create_timer(2.0).timeout
		ghost.queue_free()
	else:
		print("👻 You lost! Returning to building.")
		dialogue_label.text = "You lost! Returning to building."
		dialogue_panel.visible = true
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://buildingpage.tscn")
	hide_rps()

func _on_rps_result(success: bool, ghost_name: String) -> void:
	print("🎯 _on_rps_result called with success =", success, " ghost_name =", ghost_name)
	if not success:
		dialogue_label.text = "You lost! Returning to building."
		dialogue_label.visible = true
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://buildingpage.tscn")
	else:
		dialogue_label.text = "%s: Hmph... you win..." % ghost_name
		dialogue_label.visible = true
		await get_tree().create_timer(2.0).timeout
		var ghost = $Interactables.get_node_or_null(ghost_name)
		if ghost:
			ghost.queue_free()

func show_rps(ghost_name: String) -> void:
	$UI.visible = false
	rps_popup.show_rps(ghost_name)
	rps_popup.grab_focus()

func hide_rps() -> void:
	rps_popup.hide()
	$UI.visible = true
	$UI.grab_focus()

func _on_item_picked_up(item_name):
	print("🪙 Collected:", item_name)

func _on_ghost_interacted(ghost_id):
	print("👻 Talked to ghost:", ghost_id)

func _on_room_inspected(room_name: String):
	if visited_flags.get(room_name, false):
		return

	visited_flags[room_name] = true
	visited_rooms += 1
	print("✅ Inspected:", room_name)
	progress_label.text = "Rooms Inspected: %d / %d" % [visited_rooms, total_rooms]
	if visited_rooms >= total_rooms:
		print("🎉 All rooms inspected!")
		unlock_button.visible = true

func _on_unlock_button_pressed():
	print("🔓 Unlock button pressed")

	if inspected_floor_index == -1:
		return
	var floor = Global.building_floors[inspected_floor_index]
	floor["state"] = Global.FloorState.READY
	if not floor.has("type") or floor["type"] == null:
		floor["type"] = "Unassigned"
	Global.building_floors[inspected_floor_index] = floor

	print("🏁 Floor %d marked READY!" % (inspected_floor_index + 1))
	inspection_complete.emit(inspected_floor_index)
	# Remove this scene from the tree before switching
	queue_free()
	# Go back to building page
	get_tree().change_scene_to_file("res://BuildingPage.tscn")
