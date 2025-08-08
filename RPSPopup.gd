extends Control

signal rps_result(success: bool, ghost_name: String)

@onready var prompt_label = $Panel/PromptLabel
@onready var result_label = $Panel/ResultLabel
@onready var rock_button = $Panel/HBoxContainer/RockButton
@onready var paper_button = $Panel/HBoxContainer/PaperButton
@onready var scissors_button = $Panel/HBoxContainer/ScissorsButton

var current_ghost_name: String = ""

func _ready():
	rock_button.pressed.connect(func(): _on_choice_selected("rock"))
	paper_button.pressed.connect(func(): _on_choice_selected("paper"))
	scissors_button.pressed.connect(func(): _on_choice_selected("scissors"))
	hide()

func show_rps(ghost_name: String):
	current_ghost_name = ghost_name
	result_label.text = ""
	rock_button.disabled = false
	paper_button.disabled = false
	scissors_button.disabled = false
	show()

func _on_choice_selected(player_choice: String):
	print("Player chose:", player_choice)
	var ghost = get_parent().get_node("Interactables").get_node(current_ghost_name)
	if ghost == null:
		print("❌ Couldn't find ghost:", current_ghost_name)
		return

	var result = ghost.play_rps_with_choice(player_choice)
	print("RPS result:", result)
	match result:
		"tie":
			result_label.text = "🤝 It's a tie. Try again!"
		"win":
			result_label.text = "✅ You Win!"
			rock_button.disabled = true
			paper_button.disabled = true
			scissors_button.disabled = true
			await get_tree().create_timer(2.0).timeout
			hide()
			print("Emitting rps_result with success =", true, "ghost_name =", current_ghost_name)
			emit_signal("rps_result", true, current_ghost_name)
		"lose":
			result_label.text = "❌ You Lose!"
			rock_button.disabled = true
			paper_button.disabled = true
			scissors_button.disabled = true
			await get_tree().create_timer(2.0).timeout
			hide()
			print("Emitting rps_result with success =", false, "ghost_name =", current_ghost_name)
			emit_signal("rps_result", false, current_ghost_name)
