extends Control

const ROWS = 13
const COLS = 7
const SLOT_SIZE = Vector2(31, 31)
const MIDDLE_COL = 3

@export var room_scene: PackedScene
@onready var grid = $GridContainer
@onready var manage_panel = $ManagePanel  # A VBoxContainer with buttons
@onready var add_room_button = $AddRoomButton

var floor_index := -1
var floor_data: Dictionary = {}
var add_mode := false
var building_manage_mode := false  # Building-wide manage mode

# Map rows to floors (Row0 = Floor1, Row1 = Floor2, etc.)
var row_to_floor: Array = []

func _ready():
	# Manage panel starts hidden until Manage button clicked
	add_room_button.visible = true
	add_mode = false
	building_manage_mode = false
	add_room_button.text = "Add Room"

	add_room_button.pressed.connect(_on_add_room_pressed)

	# Build row-to-floor mapping (bottom-up)
	for r in range(ROWS):
		row_to_floor.append(r)

	# Generate grid: Row0 = bottom, Row12 = top
	for r in range(ROWS):
		var display_row = ROWS - 1 - r

		for c in range(COLS):
			var slot = ColorRect.new()
			slot.name = "Slot_%d_%d" % [display_row, c]
			slot.custom_minimum_size = SLOT_SIZE
			slot.mouse_filter = Control.MOUSE_FILTER_PASS

			var row = r
			var col = c

			slot.connect("mouse_entered", Callable(self, "_on_slot_hovered").bind(row, col))
			slot.connect("mouse_exited", Callable(self, "_on_slot_unhovered").bind(row, col))
			slot.connect("gui_input", Callable(self, "_on_slot_input").bind(row, col))

			# Default: middle column red
			if c == MIDDLE_COL:
				slot.color = Color(0.8, 0.2, 0.2)
			else:
				slot.color = Color(0.2, 0.2, 0.2)

			grid.add_child(slot)

func setup(floor_idx, data):
	floor_index = floor_idx

	# Determine if single floor or building-wide array
	if typeof(data) == TYPE_ARRAY:
		if floor_idx >= 0 and floor_idx < data.size():
			floor_data = data[floor_idx]
		else:
			floor_data = {}
	elif typeof(data) == TYPE_DICTIONARY:
		floor_data = data
	else:
		floor_data = {}

	_load_rooms()

# --------------------- Load existing rooms ---------------------
func _load_rooms():
	if floor_index == -1:
		print("🔹 _load_rooms() in building-wide manage mode")
		for f_idx in range(Global.building_floors.size()):
			var floor = Global.building_floors[f_idx]
			if not floor.has("rooms"):
				continue
			print("   Floor %d rooms from Global:" % (f_idx + 1))
			for cell in floor["rooms"]:
				if typeof(cell) == TYPE_DICTIONARY and cell.has("row") and cell.has("col"):
					_fill_slot(cell["row"], cell["col"])
					print("      Room ID=%s row=%d col=%d" % [cell["id"], cell["row"], cell["col"]])
				else:
					push_error("Invalid room entry in floor %d: %s" % [f_idx, cell])
	else:
		print("🔹 _load_rooms() for floor_index:%d" % floor_index)
		if floor_data == null:
			return

		if not floor_data.has("rooms") or floor_data["rooms"].size() == 0:
			var default_scene_path = room_scene.resource_path if room_scene else "res://Scenes/Rooms/RoomA.tscn"
			var default_room = {
				"id": "floor_%d_room_1" % floor_index,
				"scene": default_scene_path,
				"row": 0,
				"col": MIDDLE_COL
			}
			floor_data["rooms"] = [default_room]
			if floor_index >= 0 and floor_index < Global.building_floors.size():
				Global.building_floors[floor_index] = floor_data

		print("   Rooms in UI for floor %d:" % floor_index)
		for cell in floor_data["rooms"]:
			if typeof(cell) == TYPE_DICTIONARY and cell.has("row") and cell.has("col"):
				_fill_slot(cell["row"], cell["col"])
				print("      Room ID=%s row=%d col=%d" % [cell["id"], cell["row"], cell["col"]])
			else:
				push_error("Invalid room entry in floor_data['rooms']: %s" % cell)


# --------------------- Place a new room ------------------------
func _place_room(row: int, col: int):
	var scene_path = room_scene.resource_path if room_scene else "res://Scenes/Rooms/RoomA.tscn"

	if building_manage_mode:
		var target_floor_index = row_to_floor[row] if row < row_to_floor.size() else 0
		var floor = Global.building_floors[target_floor_index]

		if floor["state"] != Global.FloorState.READY:
			print("⚠ Cannot add room to Floor %d: not READY" % (target_floor_index + 1))
			return

		if not floor.has("rooms"):
			floor["rooms"] = []

		var room_id = "floor_%d_room_%d" % [target_floor_index, floor["rooms"].size() + 1]
		var new_room = {"id": room_id, "scene": scene_path, "row": row, "col": col}
		floor["rooms"].append(new_room)
		Global.building_floors[target_floor_index] = floor

		print("🟢 Added room to Floor %d with ID %s at row %d, col %d" % [target_floor_index + 1, room_id, row, col])
		print("   Current rooms on this floor:")
		for r in floor["rooms"]:
			print("      %s at row %d, col %d" % [r["id"], r["row"], r["col"]])
	else:
		_fill_slot(row, col)

		if floor_data == null:
			print("⚠ floor_data is null, cannot add room.")
			return

		Global.add_room_to_floor(floor_index, scene_path, row, col)
		floor_data = Global.building_floors[floor_index]

		print("🟢 Added room to Floor %d (floor_index) via floor_data with ID %s at row %d, col %d"
			% [floor_index + 1, "new_room?", row, col])
		print("   Updated floor_data['rooms'] now has %d entries" % floor_data["rooms"].size())
		for r in floor_data["rooms"]:
			print("      %s at row %d, col %d" % [r["id"], r["row"], r["col"]])

	_fill_slot(row, col)



# --------------------- Button & Hover Handling -----------------
func _on_add_room_pressed():
	add_mode = !add_mode
	building_manage_mode = add_mode
	add_room_button.text = "Cancel Add Room" if add_mode else "Add Room"

func _on_slot_hovered(row, col):
	if not add_mode:
		return

	var target_floor_index = row_to_floor[row]
	var floor = Global.building_floors[target_floor_index]

	# Only show hover for READY floors
	if floor["state"] != Global.FloorState.READY:
		return

	var slot = grid.get_node("Slot_%d_%d" % [_row_to_display(row), col])
	if slot.color == Color(0.8, 0.2, 0.2):
		return
	if _is_adjacent_to_red(row, col):
		slot.color = Color(1, 0.5, 0.5)
	else:
		slot.color = Color(0.2, 0.2, 0.2)


func _on_slot_unhovered(row, col):
	var slot = grid.get_node("Slot_%d_%d" % [_row_to_display(row), col])
	if slot.color != Color(0.8, 0.2, 0.2):
		slot.color = Color(0.2, 0.2, 0.2)

func _on_slot_input(event, row, col):
	if not add_mode:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_floor_index = row_to_floor[row]
		var floor = Global.building_floors[target_floor_index]

		# Only allow clicks on READY floors
		if floor["state"] != Global.FloorState.READY:
			return

		var slot = grid.get_node("Slot_%d_%d" % [_row_to_display(row), col])
		if slot.color == Color(0.8, 0.2, 0.2):
			return
		if _is_adjacent_to_red(row, col):
			_place_room(row, col)
			add_mode = false
			building_manage_mode = false
			add_room_button.text = "Add Room"


func _row_to_display(row: int) -> int:
	return ROWS - 1 - row

func _fill_slot(row: int, col: int):
	var display_row = _row_to_display(row)
	var slot = grid.get_node("Slot_%d_%d" % [display_row, col])
	if slot:
		slot.color = Color(0.8, 0.2, 0.2)

func _is_adjacent_to_red(row, col) -> bool:
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if abs(dr) + abs(dc) != 1:
				continue
			var nr = row + dr
			var nc = col + dc
			if nr < 0 or nr >= ROWS or nc < 0 or nc >= COLS:
				continue
			var neighbor = grid.get_node("Slot_%d_%d" % [_row_to_display(nr), nc])
			if neighbor.color == Color(0.8, 0.2, 0.2):
				return true
	return false
