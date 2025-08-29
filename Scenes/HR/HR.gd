extends Node2D

@onready var exit_to_hallway = $ExitToHallway
@onready var interact_button = $InteractButton
@onready var spawn = $SpawnPoint
var player: Node2D = null
var interacted: bool = false

# Track locked/highlighted state
var locked_images = Global.HR_state["locked_images"]
var selected = Global.HR_state["selected"]

# ---------- Dialogue map ----------
var quest_dialogues = {
	4: {0: [
		{"speaker": "HR", "text": "All your paperwork is done!"}
	]},
	6: {0: [
		{"speaker": "HR Lady", "text": "Hey! Now you can manage your Hiring page."},
		{"speaker": "HR Lady", "text": "Click the Hiring icon to hire employees and expand your team."}
	]}
}

func _ready():
	# Quest4 enter HR
	if QuestManager.current_quest_id == 2:
		QuestManager.complete_requirement(2, 1)
		print("✅ Quest 2 Task 'enter_hr' complete")

	interacted = Global.HR_state.interacted if "interacted" in Global.HR_state else false
	interact_button.pressed.connect(_on_interact_pressed)

	# Player spawn
	player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = spawn.global_position
	else:
		push_error("⚠️ Player not found in Hallway0")

	exit_to_hallway.body_entered.connect(_on_exit_door)

	# GUI input for images
	$DepartmentImage.gui_input.connect(_on_department_input)
	$HiringImage.gui_input.connect(_on_hiring_input)
	$StaffImage.gui_input.connect(_on_staff_input)
	$BulletinImage.gui_input.connect(_on_bulletin_input)

	# Apply persistent HR states and hover effects
	for key in ["department", "hiring", "staff", "bulletin"]:
		var node = get_node_for_key(key)
		if node:
			var unlocked = not Global.HR_state.locked_images.get(key, true)
			var sel = Global.HR_state.selected.get(key, false)
			_set_interactable(node, unlocked, sel)
			_highlight(node, sel)
			node.mouse_entered.connect(func(): _set_hover(node, true))
			node.mouse_exited.connect(func(): _set_hover(node, false))

	# If Quest6 is complete, ensure everything is unlocked (safety on reload)
	if _is_quest_completed(6):
		unlock_all_images()

	Fade.fade_in(0.5)

# ---------- Helpers ----------
func _is_quest_completed(quest_id: int) -> bool:
	if not QuestManager.quests.has(quest_id):
		return false
	var reqs = QuestManager.quests[quest_id].get("requirements", [])
	for r in reqs:
		if not r.get("completed", false):
			return false
	return true

func _set_interactable(node: TextureRect, interactable: bool, highlight: bool=false):
	node.mouse_filter = Control.MOUSE_FILTER_PASS if interactable else Control.MOUSE_FILTER_IGNORE
	_highlight(node, highlight)

func _highlight(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("outline_enabled", enable)

func _set_hover(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("glow_enabled", enable)

func get_node_for_key(key: String) -> TextureRect:
	match key:
		"department": return $DepartmentImage
		"hiring": return $HiringImage
		"staff": return $StaffImage
		"bulletin": return $BulletinImage
		_: return null

func load_subpage(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		Global.clear_children($ContentContainer)
		if instance is Window:
			get_tree().current_scene.add_child(instance)
		else:
			$ContentContainer.add_child(instance)

# ---------- Input handlers ----------
func _on_department_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("department", $DepartmentImage, "res://Scenes/HR/Department.tscn")

func _on_hiring_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("hiring", $HiringImage, "res://Scenes/HR/Hiring.tscn")

func _on_staff_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("staff", $StaffImage, "res://Scenes/HR/Staff.tscn")

func _on_bulletin_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click("bulletin", $BulletinImage, "res://Scenes/HR/BulletinBoard.tscn")

# ---------- Core click logic ----------
func _handle_click(key: String, node: TextureRect, path: String):
	# Must talk to HR first unless clicking Hiring
	if not Global.HR_state.has("interacted") or not Global.HR_state.interacted:
		if key != "hiring":
			print("Cannot click before interacting with HR")
			return

	# Quest6 restrictions before completion: Hiring -> Department
	if QuestManager.current_quest_id == 6 and not _is_quest_completed(6):
		var hire_done = QuestManager.quests[6]["requirements"][2]["completed"]
		if key == "department" and not hire_done:
			print("Department clicked before Hiring completed")
			return
		if key != "hiring" and not Global.HR_state.selected["hiring"]:
			return

	# Mark selection + persist unlock
	if not Global.HR_state.selected[key]:
		_highlight(node, true)
		Global.HR_state.selected[key] = true
		Global.HR_state.locked_images[key] = false

	# Quest6 step completions
	if key == "hiring":
		QuestManager.complete_requirement(6, 2)
		print("Hiring requirement completed")
		unlock_department_step()
	elif key == "department":
		QuestManager.complete_requirement(6, 3)
		print("Department requirement completed")

	# If Quest6 is fully complete, unlock everything
	if _is_quest_completed(6):
		unlock_all_images()

	load_subpage(path)

func unlock_department_step():
	print("Unlocking Department after Hiring")
	_set_interactable($DepartmentImage, true, true)

func unlock_all_images():
	print("Unlocking ALL HR images after Quest6 complete")
	for key in ["department", "hiring", "staff", "bulletin"]:
		var node = get_node_for_key(key)
		if node:
			_set_interactable(node, true, true)
			selected[key] = true
			Global.HR_state.locked_images[key] = false

# ---------- Exit ----------
func _on_exit_door(body):
	if body.name != "Player":
		return
	print("Exit HR → Hallway0 triggered")
	var floor0_root = get_parent().get_parent()
	if floor0_root and floor0_root.has_method("load_room"):
		floor0_root.load_room("res://Scenes/Rooms/Hallway0.tscn")
	else:
		push_error("Cannot find Floor0 root to load Hallway0")

# ---------- Interact button ----------
func _on_interact_pressed():
	Global.HR_state.interacted = true
	interacted = true
	print("Interacting with HRLady")

	var quest_id = QuestManager.current_quest_id
	var req_index = QuestManager.get_current_requirement_index()

	# Quest-specific dialogues
	var dialogue_lines = quest_dialogues.get(quest_id, {}).get(req_index, [])

	if dialogue_lines.size() > 0:
		var dialogue_node = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
		if dialogue_node:
			dialogue_node.start(dialogue_lines)
		else:
			push_error("Dialogue node not found!")
	else:
		var dialogue_node = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
		if dialogue_node:
			dialogue_node.start([{"speaker": "HR Lady", "text": "I am busy at the moment."}])
		else:
			push_error("Dialogue node not found!")

	# Quest requirement completions
	if quest_id == 4:
		if not QuestManager.quests[4]["requirements"][0]["completed"]:
			QuestManager.complete_requirement(4, 0)
			print("Quest4: talk_to_hr done")

	if quest_id == 6:
		if not QuestManager.quests[6]["requirements"][1]["completed"]:
			QuestManager.complete_requirement(6, 1)
			print("Quest6: talk_to_hr done")

		# Enable only Hiring at first
		_set_interactable($HiringImage, true, true)
		selected["hiring"] = true
		Global.HR_state.locked_images["hiring"] = false

		# Keep others locked until progression finishes
		_set_interactable($DepartmentImage, false)
		_set_interactable($StaffImage, false)
		_set_interactable($BulletinImage, false)

		# If Quest6 already complete when talking (edge case), unlock all
		if _is_quest_completed(6):
			unlock_all_images()
