extends Control

const ROWS = 13
const COLS = 7
const SLOT_SIZE = Vector2(31, 31)
const MIDDLE_COL = 3

@export var room_scene: PackedScene
@onready var grid = $GridContainer
@onready var add_room_button = $AddRoomButton

var floor_index := -1
var floor_data: Dictionary = {}
var add_mode := false
var max_allowed_row := -1

func _ready():
	add_room_button.pressed.connect(_on_add_room_pressed)

	# Generate grid: Row0 = bottom, Row12 = top
	for r in range(ROWS):
		var display_row = ROWS - 1 - r  # bottom-up

		for c in range(COLS):
			var slot = ColorRect.new()
			slot.name = "Slot_%d_%d" % [display_row, c]
			slot.custom_minimum_size = SLOT_SIZE
			slot.mouse_filter = Control.MOUSE_FILTER_PASS

			# Local copies for binding
			var row = r  # logical row
			var col = c

			slot.connect("mouse_entered", Callable(self, "_on_slot_hovered").bind(row, col))
			slot.connect("mouse_exited", Callable(self, "_on_slot_unhovered").bind(row, col))
			slot.connect("gui_input", Callable(self, "_on_slot_input").bind(row, col))

			# Fill middle column as existing rooms
			if c == MIDDLE_COL:
				slot.color = Color(0.8, 0.2, 0.2)
			else:
				slot.color = Color(0.2, 0.2, 0.2)

			grid.add_child(slot)

func setup(floor_idx, data):
	floor_index = floor_idx
	floor_data = data

	# Determine highest allowed row based on READY floors
	max_allowed_row = -1
	for i in range(floor_index + 1):
		if Global.building_floors[i]["state"] == Global.FloorState.READY:
			max_allowed_row = i
	_load_rooms()

func _load_rooms():
	if floor_data == null or not floor_data.has("rooms"):
		return
	for cell in floor_data["rooms"]:
		_fill_slot(cell["row"], cell["col"])

func _row_to_display(row: int) -> int:
	return ROWS - 1 - row


func _fill_slot(row: int, col: int):
	var display_row = _row_to_display(row)
	var slot = grid.get_node("Slot_%d_%d" % [display_row, col])
	if slot:
		slot.color = Color(0.8, 0.2, 0.2)


func _on_add_room_pressed():
	add_mode = !add_mode
	add_room_button.text = "Cancel Add Room" if add_mode else "Add Room"

func _on_slot_hovered(row, col):
	if not add_mode:
		return
	if row > max_allowed_row:
		return  # cannot hover above allowed rows

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


func _on_slot_input(event, row, col):
	if not add_mode:
		return
	if row > max_allowed_row:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var slot = grid.get_node("Slot_%d_%d" % [_row_to_display(row), col])
		if slot.color == Color(0.8, 0.2, 0.2):
			return
		if _is_adjacent_to_red(row, col):
			_place_room(row, col)
			add_mode = false
			add_room_button.text = "Add Room"


func _place_room(row: int, col: int):
	_fill_slot(row, col)
	if floor_data == null:
		return
	if not floor_data.has("rooms"):
		floor_data["rooms"] = []
	for cell in floor_data["rooms"]:
		if cell["row"] == row and cell["col"] == col:
			return
	floor_data["rooms"].append({"row": row, "col": col})
	Global.building_floors[floor_index] = floor_data
