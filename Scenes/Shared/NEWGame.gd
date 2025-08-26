extends Node

var current_scene: Node = null
@onready var check_list_ui: Node = HUD.get_node("CanvasLayer/CheckListUI")

@export var debug_start_quest: int = -1

func _ready():
	print("NEWGame ready")

	# --- Initialize floors first ---
	if Global.building_floors.size() == 0:
		Global.init_building_floors()

	if not check_list_ui:
		push_error("⚠️ ChecklistUI NOT FOUND in HUD!")
	else:
		print("✅ ChecklistUI found:", check_list_ui)

	# Connect QuestManager signals
	if check_list_ui:
		QuestManager.connect("requirement_completed", Callable(check_list_ui, "update_requirement"))
		QuestManager.connect("quest_completed", Callable(check_list_ui, "_on_finish_pressed"))
		QuestManager.connect("quest_updated", Callable(check_list_ui, "update_quest"))
		print("✅ ChecklistUI connected to QuestManager signals")

	# Load initial scene
	load_scene("res://Scenes/Floors/Floor0.tscn")

	# Debug skip to quest
	if debug_start_quest >= 0:
		_debug_skip_to_quest(debug_start_quest)
	else:
		QuestManager.start_quest(0)

func load_scene(path: String):
	if current_scene:
		current_scene.queue_free()

	var scene_res = load(path)
	if not scene_res:
		push_error("Failed to load scene: " + path)
		return

	current_scene = scene_res.instantiate()
	add_child(current_scene)
	print("Loaded scene:", path)

func _debug_skip_to_quest(quest_index: int) -> void:
	for i in range(quest_index):
		var q = QuestManager.quests[i]
		q["reward_claimed"] = true
		for req in q["requirements"]:
			req["completed"] = true
	print("Debug: Skipped to Quest %d" % quest_index)
	QuestManager.start_quest(quest_index)
