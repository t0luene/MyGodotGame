extends Control

@onready var bar = $BarIndicator
@onready var left_button = $LeftButton
@onready var right_button = $RightButton

var is_balancing: bool = false

func _ready():
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)
	hide()

# Called from BalanceArea to update bar position
func update_bar(balance_value: float, fail_threshold: float):
	if bar:
		bar.position.x = clamp(balance_value / fail_threshold * 100, -100, 100)

func show_bar():
	is_balancing = true
	visible = true

func hide_bar():
	is_balancing = false
	visible = false

func _on_left_button_pressed():
	if is_balancing:
		var balance_area = get_tree().current_scene.get_node("BalanceArea")
		balance_area.push_balance(-1)  # just push -1, BalanceArea scales it

func _on_right_button_pressed():
	if is_balancing:
		var balance_area = get_tree().current_scene.get_node("BalanceArea")
		balance_area.push_balance(1)   # just push +1
