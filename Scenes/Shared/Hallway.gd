extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var door_container: Node2D = $DoorContainer
@onready var crew_stairs_button = $UI/CrewStairsButton
@onready var elevator_button = $UI/ElevatorButton
@export var floor_index: int = -1  # must be set when you spawn the hallway

signal entrance_pressed(target_room_path: String)
signal crew_stairs_pressed()
signal elevator_pressed()


var connected_rooms: Array[String] = []  # <--- ensure typed as Array[String]


func set_floor_index(idx: int) -> void:
	floor_index = idx
	print("🔹 Hallway floor_index set to:", floor_index)


func _ready():
	print("✅ Hallway ready")
	floor_index = Global.current_inspection_floor if "current_inspection_floor" in Global else -1
	print("Hallway ready with floor_index:", floor_index)
	if crew_stairs_button:
		crew_stairs_button.pressed.connect(Callable(self, "_on_crew_stairs_pressed"))

	if floor_index < 0 or floor_index >= Global.building_floors.size():
		push_error("⚠ Invalid floor_index in Hallway _ready(): %d" % floor_index)
		return

	var floor_data = Global.building_floors[floor_index]
	var room_paths: Array[String] = []

	# Add default room if none exist
	if floor_data.has("rooms") and floor_data["rooms"].size() > 0:
		for room_dict in floor_data["rooms"]:
			room_paths.append(str(room_dict["scene"]))
	else:
		# Default single room to ensure at least one door
		room_paths.append("res://Scenes/Shared/RoomSquare.tscn")

	print("📦 Floor %d has %d room(s):" % [floor_index + 1, room_paths.size()])
	for r in room_paths:
		print("   Room Scene:", r)
		

	setup_hallway(room_paths)


# -------------------------
# Generate doors dynamically
# -------------------------
func _generate_doors() -> void:
	print("🔧 Generating doors for rooms:", connected_rooms)

	# Clear old doors
	for child in door_container.get_children():
		child.queue_free()
	print("🧹 Cleared old doors")

	for i in range(connected_rooms.size()):
		var room_path: String = connected_rooms[i]
		print("➡ Creating door for:", room_path)

		var door_scene = preload("res://Scenes/Shared/Door.tscn")
		var door_instance = door_scene.instantiate()
		door_container.add_child(door_instance)
		print("✅ Door instance added")

		var placeholder_name = "Room%dPos" % (i + 1)
		var placeholder = $DoorPositions.get_node_or_null(placeholder_name)
		if placeholder:
			door_instance.position = placeholder.global_position
			print("📍 Door positioned at:", placeholder_name, " -> ", door_instance.position)
		else:
			push_warning("⚠ Door placeholder '%s' not found!" % placeholder_name)

		door_instance.pressed.connect(func():
			print("📢 Door pressed signal received for:", room_path)
			_on_door_pressed(room_path))

	# Now update background once
	_update_background()
	

# -------------------------
# Setup hallway with a list of rooms
# -------------------------
func setup_hallway(rooms: Array) -> void:
	# Convert rooms to Array[String] if they are not already
	connected_rooms.clear()
	for r in rooms:
		connected_rooms.append(str(r))

	print("🛠 setup_hallway called with:", connected_rooms)
	_generate_doors()  # background update happens inside _generate_doors()

	
	
# -------------------------
# Update background based on doors
# -------------------------
func _update_background() -> void:
	print("🖼 Updating background for door count:", connected_rooms.size())
	match connected_rooms.size():
		1,2,3,4,5,6,7:
			$Background.texture = preload("res://Assets/Rooms/Hallway2.png")
			
#-----ROOMS------

func _print_floor_rooms():
	if floor_index < 0 or floor_index >= Global.building_floors.size():
		print("⚠ Invalid floor_index:", floor_index)
		return

	var floor = Global.building_floors[floor_index]
	if floor.has("rooms") and floor["rooms"] is Array:
		print("📦 Floor %d has %d room(s):" % [floor_index + 1, floor["rooms"].size()])
		for room_dict in floor["rooms"]:
			print("   Room ID:", room_dict.get("id", "N/A"),
				  "Scene:", room_dict.get("scene", "N/A"),
				  "Row:", room_dict.get("row", "N/A"),
				  "Col:", room_dict.get("col", "N/A"))
	else:
		print("📦 Floor %d has no rooms!" % (floor_index + 1))




# -------------------------
# Handle door press
# -------------------------
func _on_door_pressed(room_path: String):
	print("🚪 _on_door_pressed called with:", room_path)

	var room_scene: PackedScene = load(room_path)
	if not room_scene:
		push_error("❌ Failed to load room: %s" % room_path)
		return

	var room_instance = room_scene.instantiate()

	var floor_data = Global.building_floors[floor_index]

	if not floor_data.has("floor_id"):
		floor_data["floor_id"] = "floor_%d" % floor_index

	if not floor_data.has("rooms"):
		floor_data["rooms"] = []

	if not floor_data.has("room_ids"):
		floor_data["room_ids"] = []

	var room_index = floor_data["rooms"].find(room_path)

	if room_index == -1:
		floor_data["rooms"].append(room_path)
		room_index = floor_data["rooms"].size() - 1   # recompute the correct index
		print("➕ Added new room to floor %d: %s" % [floor_index + 1, room_path])

	if room_index >= floor_data["room_ids"].size():
		floor_data["room_ids"].append("%s_room_%d" % [floor_data["floor_id"], room_index + 1])

	Global.building_floors[floor_index] = floor_data

	room_instance.room_id = floor_data["room_ids"][room_index]
	print("🚀 Room instance ID:", room_instance.room_id)
	print("📦 Floor %d now has %d room(s)" % [floor_index + 1, floor_data["rooms"].size()])

	call_deferred("_switch_to_room", room_instance)


func _switch_to_room(room_instance: Node2D):
	var current = get_tree().current_scene
	if current:
		current.queue_free()
	get_tree().root.add_child(room_instance)
	get_tree().current_scene = room_instance

# -------------------------
# Crew stairs button
# -------------------------
# HallwayDynamic.gd

func _on_crew_stairs_pressed():
	print("🔹 CrewStairsButton pressed for floor_index:", floor_index)

	# Safety check
	if floor_index < 0 or floor_index >= Global.building_floors.size():
		push_error("❌ Invalid floor_index! Cannot mark floor READY.")
		return

	# Mark floor READY
	Global.set_floor_state(floor_index, Global.FloorState.READY)
	print("✅ Floor %d marked READY via Global" % (floor_index + 1))

	# Fade out
	if Fade.has_method("fade_out"):
		print("🎨 Starting fade out")
		Fade.fade_out(0.5)
		await get_tree().create_timer(0.5).timeout
		print("🎨 Fade out complete")

	# Return to Maintenance
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
