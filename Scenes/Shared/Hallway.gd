extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var door_container: Node2D = $DoorContainer
@onready var crew_stairs_button = $UI/CrewStairsButton
@onready var elevator_button = $UI/ElevatorButton

signal entrance_pressed(target_room_path: String)
signal crew_stairs_pressed()
signal elevator_pressed()

var connected_rooms: Array[String] = []

func _ready():
	print("✅ Hallway ready")

	# Connect buttons
	if crew_stairs_button:
		crew_stairs_button.pressed.connect(_on_crew_stairs_pressed)
	else:
		push_error("❌ CrewStairsButton not found!")

	if elevator_button:
		elevator_button.pressed.connect(_on_elevator_pressed)
	else:
		push_error("❌ ElevatorButton not found!")

	Fade.fade_in(0.5)

	# Setup test doors
	setup_hallway([
		"res://Scenes/Rooms/RoomA.tscn",
	])

# -------------------------
# Setup hallway with a list of rooms
# -------------------------
func setup_hallway(rooms: Array[String]):
	print("🛠 setup_hallway called with:", rooms)
	connected_rooms = rooms
	_generate_doors()
	_update_background()

# -------------------------
# Generate doors dynamically
# -------------------------
func _generate_doors():
	print("🔧 Generating doors for rooms:", connected_rooms)

	# Clear old doors
	for child in door_container.get_children():
		child.queue_free()
	print("🧹 Cleared old doors")

	for i in range(connected_rooms.size()):
		var room_path = connected_rooms[i]
		print("➡ Creating door for:", room_path)

		var door_scene = preload("res://Scenes/Shared/Door.tscn")
		var door_instance = door_scene.instantiate()
		door_container.add_child(door_instance)
		print("✅ Door instance added")

		# Position the door at placeholder
		var placeholder_name = "Room%dPos" % (i + 1)
		var placeholder = $DoorPositions.get_node_or_null(placeholder_name)
		if placeholder:
			door_instance.position = placeholder.global_position
			print("📍 Door positioned at:", placeholder_name, " -> ", door_instance.position)
		else:
			push_warning("⚠ Door placeholder '%s' not found!" % placeholder_name)

		# Connect signal
		door_instance.pressed.connect(func():
			print("📢 Door pressed signal received for:", room_path)
			_on_door_pressed(room_path)
		)

# -------------------------
# Handle door press
# -------------------------
func _on_door_pressed(room_path: String):
	print("🚪 _on_door_pressed called with:", room_path)

	# Transition effect
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout

	# Load the target room scene
	var room_scene = load(room_path)
	if not room_scene:
		push_error("❌ Failed to load room: %s" % room_path)
		return

	print("🚀 Changing scene to:", room_path)
	get_tree().change_scene_to_packed(room_scene)


# -------------------------
# Crew stairs button
# -------------------------
func _on_crew_stairs_pressed():
	print("🔹 CrewStairsButton pressed")

	# Mark Floor1 READY in Global
	Global.ensure_building_floors_initialized()
	var floor = Global.building_floors[0]
	floor["state"] = Global.FloorState.READY
	Global.building_floors[0] = floor
	print("✅ Floor1 marked READY via Global")

	# Fade out
	if Fade.has_method("fade_out"):
		Fade.fade_out(0.5)
		await get_tree().create_timer(0.5).timeout

	# Go straight back to Maintenance
	var maintenance_scene = load("res://Scenes/Maintenance/Maintenance.tscn")
	if not maintenance_scene:
		push_error("❌ Failed to load Maintenance.tscn")
		return

	print("🚀 Returning to Maintenance")
	get_tree().change_scene_to_packed(maintenance_scene)



# -------------------------
# Elevator button
# -------------------------
func _on_elevator_pressed():
	print("🔹 ElevatorButton pressed")
	emit_signal("elevator_pressed")

# -------------------------
# Background swap
# -------------------------
func _update_background():
	print("🖼 Updating background for door count:", connected_rooms.size())
	match connected_rooms.size():
		1,2,3,4,5,6,7:
			$Background.texture = preload("res://Assets/Rooms/Hallway2.png")
