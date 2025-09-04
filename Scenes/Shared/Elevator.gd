extends Control

@onready var floor_dropdown: OptionButton = $FloorDropdown
@onready var go_button: Button = $GoButton
@onready var close_button: Button = $CloseButton

# Floors list – make sure Floor-1 path is correct
var floors = [
	{"scene":"res://Scenes/Floors/Floor-2.tscn", "label":"Floor BM2"},
	{"scene":"res://Scenes/Floors/Floor-1.tscn", "label":"Floor BM1"},
	{"scene":"res://Scenes/Floors/Floor0.tscn", "label":"Floor 0"},
	{"scene":"res://Scenes/Floors/Floor1.tscn", "label":"Floor 1"},
	{"scene":"res://Scenes/Floors/Floor2.tscn", "label":"Floor 2"},
	{"scene":"res://Scenes/Floors/Floor3.tscn", "label":"Floor 3"},
	{"scene":"res://Scenes/Floors/Floor4.tscn", "label":"Floor 4"},
	{"scene":"res://Scenes/Floors/Floor5.tscn", "label":"Floor 5"}
]

func _ready():
	# Set the current floor first
	if "current_floor_index" in Global and Global.current_floor_index >= 0:
		Global.current_floor_scene = floors[Global.current_floor_index]["scene"]

	print("📍 Global.current_floor_scene is:", Global.current_floor_scene)

	# Defer setup to ensure OptionButton is ready
	call_deferred("_setup_floors")

	go_button.pressed.connect(_on_go_pressed)
	close_button.pressed.connect(_on_close_pressed)
	Fade.fade_in(0.5)


func _setup_floors():
	floor_dropdown.clear()

	print("🔹 Setting up floors. Global.current_floor_scene:", Global.current_floor_scene)

	for i in range(floors.size()):
		var f = floors[i]
		var label = f["label"]

		if f["scene"] == Global.current_floor_scene:
			label += " (YOU ARE HERE)"
			floor_dropdown.select(i)
			print("✅ Marking floor as YOU ARE HERE:", label)

		floor_dropdown.add_item(label)
		floor_dropdown.set_item_text(i, label)

	# Add locked floors (optional)
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

	# Quest step for arriving at Floor-1
	if QuestManager.current_quest_id == 4 and target_scene == "res://Scenes/Floors/Floor-1.tscn":
		QuestManager.player_arrived_floor_minus1()
	# Quest step for arriving at Floor-2 (Quest5)
	if QuestManager.current_quest_id == 5 and target_scene == "res://Scenes/Floors/Floor-2.tscn":
		QuestManager.player_arrived_grid_floor()

	# Fade and change scene
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(target_scene)

func _on_close_pressed():
	if Global.current_floor_scene != "":
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(Global.current_floor_scene)
