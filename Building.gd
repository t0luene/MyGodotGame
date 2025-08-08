extends Control

@onready var tower_page = $Tower
@onready var tech_tree_page = $BuildingTechTree

func _ready():
	print("TowerButton:", $TowerButton)
	print("TechTreeButton:", $TechTreeButton)

	$TowerButton.pressed.connect(Callable(self, "_on_tower_button_pressed"))
	$TechTreeButton.pressed.connect(Callable(self, "_on_tech_tree_button_pressed"))

	show_tower_page()

func _on_tower_button_pressed():
	show_tower_page()

func _on_tech_tree_button_pressed():
	show_tech_tree_page()

func show_tower_page():
	tower_page.visible = true
	tech_tree_page.visible = false

func show_tech_tree_page():
	tower_page.visible = false
	tech_tree_page.visible = true
