extends Control
func _on_NewGameButton_pressed():
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_ExitButton_pressed():
	get_tree().quit()


func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Game.tscn")
		
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
