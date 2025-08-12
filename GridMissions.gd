extends Control

@onready var mission_list = $Panel/ScrollContainer/MissionContainer
@onready var game_scene = preload("res://Game.tscn")

@onready var back_button = $BackButton
var mission_card_scene = preload("res://mission_card.tscn")



var mission_names = [
	"Data Mining Operation",
	"Secure the Vault",
	"Network Recon",
	"Ghost Hunt",
	"Software Debug",
	"Cyber Defense",
	"Hardware Upgrade",
	"Resource Allocation",
	"AI Training",
	"System Overclock"
]

func _on_back_button_pressed():
	print("Back button pressed")
	get_tree().change_scene_to_file("res://Game.tscn")

func _ready():
	print("GridPage ready!")
	randomize()  # Initialize RNG

	var mission_container = $Panel/ScrollContainer/MissionContainer

	# Clear any existing cards first, so we start fresh
	for child in mission_container.get_children():
		child.queue_free()

	# Create 3 unique random mission names
	var mission_names = [
		"Data Mining Operation",
		"Secure the Vault",
		"Network Recon",
		"Ghost Hunt",
		"Software Debug",
		"Cyber Defense",
		"Hardware Upgrade",
		"Resource Allocation",
		"AI Training",
		"System Overclock"
	]

	var chosen_names = []
	while chosen_names.size() < 3:
		var name = mission_names[randi() % mission_names.size()]
		if name not in chosen_names:
			chosen_names.append(name)

	# Instantiate and add the 3 mission cards
	for i in range(3):
		var card = mission_card_scene.instantiate()
		card.mission_name = chosen_names[i]
		card.mission_id = "mission_" + str(i + 1)
		card.period_seconds = 10 + i * 5
		card.reward_money = 100 + i * 50
		card.reward_xp = 10 + i * 5
		mission_container.add_child(card)

	# Now continue with your existing code
	if Global.should_reset_missions:
		print("🌞 New day detected, resetting missions from GridPage")
		reset_missions_for_new_day()
		Global.should_reset_missions = false  # Reset the flag

	# Your existing debug prints
	print("Mission list node: ", mission_list)
	print("Resolved mission_list:", mission_list)
	print("Current node name: ", name)
	print("Children of current node:")
	for c in get_children():
		print(" - ", c.name)

	# Back button signals (keep your existing code)
	$BackButton.pressed.connect(_on_back_button_pressed)
	if back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.disconnect(_on_back_button_pressed)
		print("Disconnected previous BackButton signal")
	back_button.pressed.connect(_on_back_button_pressed)

	# Assign unique mission IDs to each mission card
	for i in range(Global.mission_states.size()):
		var mission_data = Global.mission_states[i]
		var mission_card = mission_list.get_child(i)
		mission_card.load_from_state(mission_data)

	# Connect mission_started signals (keep your existing code)
	for mission_card in mission_list.get_children():
		if mission_card.mission_started.is_connected(_on_mission_completed):
			mission_card.mission_started.disconnect(_on_mission_completed)
		mission_card.mission_started.connect(_on_mission_completed)


func reset_missions_for_new_day():
	print("📆 Resetting missions for new day")

	if mission_list:
		var children = mission_list.get_children()
		print("🧾 Missions in container:", children.size())

		for mission_card in children:
			if mission_card.has_method("reset_state"):
				print("🔁 Calling reset_state() on:", mission_card.name)
				mission_card.reset_state()
			else:
				print("⚠️ This mission card has no reset_state():", mission_card.name)
	else:
		print("⚠️ mission_list is null. Check your scene structure or @onready path.")

func update_ui():
	# Update money display (adjust path to your label node)
	if $Panel.has_node("MoneyLabel"):
		$Panel/MoneyLabel.text = "Money: $" + str(Global.money)
	
	# Update each mission card’s employee selector (refresh to show busy status)
	for mission_card in $Panel/ScrollContainer/MissionContainer.get_children():
		if mission_card.has_method("_fill_employee_selector"):
			mission_card._fill_employee_selector()
	
	# Optionally, update other UI parts here as needed

func _on_mission_completed(data):
	var emp = Global.hired_employees[data.employee_index]
	print("✅ Mission completed by", emp.name)
	print("🔍 Global mission state now:", Global.mission_states)
	
	# Free employee so they become available again
	Global.free_employee(data.employee_index)

	# Add rewards to Global money or XP here
	Global.money += data.reward_money
	# (Add XP logic if you have XP system)
	
	# Update UI accordingly
	update_ui()

	
func load_from_state(state):
	print("Loading state for mission:", state)
