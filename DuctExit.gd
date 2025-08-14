extends Area2D

@onready var exit_button = $ExitButton
var duct_cat_inside: CharacterBody2D = null

func _ready():
	exit_button.visible = false
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))

func _on_body_entered(body):
	if body.is_in_group("duct_cat"):
		duct_cat_inside = body
		exit_button.visible = true

func _on_body_exited(body):
	if body == duct_cat_inside:
		duct_cat_inside = null
		exit_button.visible = false

func _on_exit_pressed():
	if duct_cat_inside:
		duct_cat_inside.exit_duct(global_position)
		duct_cat_inside = null
		exit_button.visible = false
