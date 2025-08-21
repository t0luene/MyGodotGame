extends Control

@onready var dialogue = $Dialogue
@onready var options_panel = $OptionsPanel
@onready var daily_panel = $DailyReportPanel

# Buttons
@onready var elevator_button = $OptionsPanel/ElevatorButton
@onready var staff_button    = $OptionsPanel/StaffButton
@onready var building_button = $OptionsPanel/BuildingButton
@onready var grid_button     = $OptionsPanel/GridButton

func _ready():
	# Make sure buttons are visible immediately
	Global.set_floor("floor0")  # Boss is floor0
	options_panel.visible = true
	daily_panel.visible = true
	Fade.fade_in(0.5)

	# Connect navigation buttons
	elevator_button.pressed.connect(_on_elevator_pressed)
	staff_button.pressed.connect(_on_staff_pressed)
	building_button.pressed.connect(_on_building_pressed)
	grid_button.pressed.connect(_on_grid_pressed)

	# Example intro dialogue
	var intro_lines = [
		"Welcome to the company!",
		"I’m your boss. I’ll guide you through your first steps.",
		"First, let’s learn how to hire an employee."
	]

	# Connect dialogue finished before starting
	dialogue.dialogue_finished.connect(_on_intro_finished)
	dialogue.start(intro_lines)
	

func _on_intro_finished():
	# Can add tutorial logic here if needed
	print("Intro finished")


# --- Navigation handlers ---
func _on_elevator_pressed():
	Fade.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Shared/Elevator.tscn")

func _on_staff_pressed():
	get_tree().change_scene_to_file("res://Scenes/HR/HR.tscn")

func _on_building_pressed():
	get_tree().change_scene_to_file("res://Scenes/Maintenance/Maintenance.tscn")

func _on_grid_pressed():
	get_tree().change_scene_to_file("res://Scenes/Grid/Grid.tscn")
