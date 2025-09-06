extends VBoxContainer

@export var room_name: String = "Room"

@onready var room_label: Label = $RoomLabel
@onready var slots_grid: GridContainer = $EmployeeSlotsGrid
@onready var slot_buttons: Array = [ $EmployeeSlotsGrid/slot_1, $EmployeeSlotsGrid/slot_2, $EmployeeSlotsGrid/slot_3 ]

func _ready():
	room_label.text = room_name
	_setup_slots()

func _setup_slots():
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		btn.text = "+"
		btn.icon = null
		# Connect the pressed signal if needed
		if not btn.is_connected("pressed", Callable(self, "_on_slot_pressed")):
			btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(i))

func _on_slot_pressed(slot_index: int) -> void:
	emit_signal("slot_pressed", room_name, slot_index)

signal slot_pressed(room_name: String, slot_index: int)
