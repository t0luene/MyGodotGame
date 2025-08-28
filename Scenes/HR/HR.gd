extends Node2D

@onready var exit_to_hallway = $ExitToHallway
@onready var interact_button = $InteractButton
@onready var spawn = $SpawnPoint
var player: Node2D = null
var interacted: bool = false  # local for convenience

# Track locked/highlighted state
var locked_images = Global.HR_state["locked_images"]
var selected = Global.HR_state["selected"]

func _ready():
	if QuestManager.current_quest_id == 2:
		# Task 1 = enter_hr
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

	# Apply persistent HR states
	for key in ["department", "hiring", "staff", "bulletin"]:
		var node = get_node_for_key(key)
		if node:
			var unlocked = not Global.HR_state.locked_images.get(key, true)
			var sel = Global.HR_state.selected.get(key, false)

			_set_interactable(node, unlocked, sel)
			_highlight(node, sel)

			# Mouse hover
			node.mouse_entered.connect(func(): _set_hover(node, true))
			node.mouse_exited.connect(func(): _set_hover(node, false))
	Fade.fade_in(0.5)


# ---------- Helper functions ----------
func _set_interactable(node: TextureRect, interactable: bool, highlight: bool=false):
	node.mouse_filter = Control.MOUSE_FILTER_PASS if interactable else Control.MOUSE_FILTER_IGNORE
	_highlight(node, highlight)

func _highlight(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("outline_enabled", enable)

func _set_hover(node: TextureRect, enable: bool):
	if node.material:
		node.material.set_shader_parameter("glow_enabled", enable)

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
	# -----------------------------
	# Require Interact first
	# -----------------------------
	if not Global.HR_state.has("interacted") or not Global.HR_state.interacted:
		if key != "hiring":  # Only allow Hiring before Interact is pressed
			print("Cannot click before interacting with HR")
			return

	# -----------------------------
	# Quest6 restrictions
	# -----------------------------
	if QuestManager.current_quest_id == 6:
		var hire_done = QuestManager.quests[6]["requirements"][2]["completed"]

		# Department only unlocks after Hiring
		if key == "department" and not hire_done:
			print("Department clicked before hiring completed, ignore")
			return

		# Prevent other buttons until Hiring is done
		if key != "hiring" and not Global.HR_state.selected["hiring"]:
			return

	# -----------------------------
	# Handle clicks
	# -----------------------------
	if not Global.HR_state.selected[key]:
		_highlight(node, true)
		Global.HR_state.selected[key] = true
		Global.HR_state.locked_images[key] = false

	if key == "hiring":
		QuestManager.complete_requirement(6, 2)  # hire_employees done
		print("Hiring requirement completed")

		# Unlock Department now
		unlock_department_step()

	elif key == "department":
		QuestManager.complete_requirement(6, 3)  # unlock_department done
		print("Department requirement completed")

	# Staff and Bulletin logic (if any) goes here
	elif key == "staff":
		pass
	elif key == "bulletin":
		pass

	# -----------------------------
	# Load the subpage if needed
	# -----------------------------
	load_subpage(path)


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


func _on_exit_door(body):
	if body.name != "Player":
		return
	print("Exit HR → Hallway0 triggered")
	var floor0_root = get_parent().get_parent()  
	if floor0_root and floor0_root.has_method("load_room"):
		floor0_root.load_room("res://Scenes/Rooms/Hallway0.tscn")
	else:
		push_error("Cannot find Floor0 root to load Hallway0")


func _on_interact_pressed():
	Global.HR_state.interacted = true
	print("Interacting with HRLady")
	interacted = true

	# ------------------------------
	# Quest4: Talk to HR
	# ------------------------------
	if QuestManager.current_quest_id == 4:
		print("Quest4: Talked to HR")
		# ✅ Mark requirement done (talk_to_hr)
		QuestManager.complete_requirement(6, 1)  # requirement index 1 = talk_to_hr

		# Show simple dialogue in HUD
		var dialogue_node = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
		if dialogue_node:
			dialogue_node.start([
				{"speaker": "HR", "text": "All your paperwork is done!"}
			])
		else:
			push_error("Dialogue node not found!")

	# ------------------------------
	# Quest6: Unlock Hiring step AFTER talking to HRLady
	# ------------------------------
	if QuestManager.current_quest_id == 6:
		print("Quest6: Unlocking Hiring step")

		# ✅ Mark the "talk_to_hr" requirement done
		QuestManager.complete_requirement(6, 1)

		# Unlock only Hiring image and highlight it
		_set_interactable($HiringImage, true, true)
		selected["hiring"] = true

		# Persist this state
		Global.HR_state.locked_images["hiring"] = false

		# Keep all others locked
		_set_interactable($DepartmentImage, false)
		_set_interactable($StaffImage, false)
		_set_interactable($BulletinImage, false)

		
		# Update selection state
		selected["hiring"] = true

		# Show dialogue explaining Hiring page
		var dialogue_node = get_node_or_null("/root/HUD/CanvasLayer/Dialogue")
		if dialogue_node:
			dialogue_node.start([
				{"speaker": "HR Lady", "text": "Hey! Now you can manage your Hiring page."},
				{"speaker": "HR Lady", "text": "Click the Hiring icon to hire employees and expand your team."}
			])
		else:
			push_error("Dialogue node not found!")


func unlock_department_step():
	print("Unlocking Department after Hiring")
	_set_interactable($DepartmentImage, true, true)
