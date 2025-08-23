extends Control

@onready var floor_dropdown: OptionButton = $FloorDropdown
@onready var go_button: Button = $GoButton
@onready var close_button: Button = $CloseButton

# Define main floors with their scene paths and labels
var floors = [
	{"scene":"res://Scenes/Floors/Floor-1.tscn", "label":"Floor -1"},
	{"scene":"res://Scenes/Boss/Boss.tscn", "label":"Floor 0"},
	{"scene":"res://Scenes/Floors/Floor1.tscn", "label":"Floor 1"},
	{"scene":"res://Scenes/Floors/Floor2.tscn", "label":"Floor 2"},
	{"scene":"res://Scenes/Floors/Floor3.tscn", "label":"Floor 3"},
	{"scene":"res://Scenes/Floors/Floor4.tscn", "label":"Floor 4"},
	{"scene":"res://Scenes/Floors/Floor5.tscn", "label":"Floor 5"}
]

func _ready():
	Fade.fade_in(0.5)

	_setup_floors()

	go_button.pressed.connect(_on_go_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _setup_floors():
	floor_dropdown.clear()

	# Add main floors to dropdown
	for i in range(floors.size()):
		var f = floors[i]
		var display_label = f["label"]

		# Highlight the current floor based on Global.current_floor_scene
		if f["scene"] == Global.current_floor_scene:
			display_label += " (YOU ARE HERE)"
			floor_dropdown.select(i)

		floor_dropdown.add_item(display_label)
		floor_dropdown.set_item_text(i, display_label)  # force exact text

	# Add locked floors (Floor 2 -> Floor 12)
	for i in range(2, 13):
		var index = floor_dropdown.get_item_count()
		var label = "Floor %d" % i
		floor_dropdown.add_item(label)
		floor_dropdown.set_item_text(index, label)
		floor_dropdown.set_item_disabled(index, true)

func _on_go_pressed():
	var selected_index = floor_dropdown.get_selected()
	if selected_index >= floors.size():
		print("Selected floor is locked")
		return

	var target_scene = floors[selected_index]["scene"]
	Global.current_floor_scene = target_scene

	# Fade out and change scene
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(target_scene)

func _on_close_pressed():
	if Global.current_floor_scene != "":
		Fade.fade_out(0.5)
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(Global.current_floor_scene)
