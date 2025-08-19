extends Control

@onready var list = $VBoxContainer

func _process(_delta):
	rebuild()  # optional: keeps updating every frame if you want

# --- NEW METHOD ---
func rebuild():
	if Global.current_floor == "":
		visible = false
		return
	
	visible = true
	
	# clear old labels
	for c in list.get_children():
		c.queue_free()
	
	# add current quests
	for quest_name in Global.get_floor_quests(Global.current_floor):
		var data = Global.quests[Global.current_floor][quest_name]
		var label = Label.new()
		label.text = data["desc"] + ": " + ("✔" if data["done"] else "❌")
		list.add_child(label)
	
	# show message if all objectives are done
	if Global.is_floor_complete(Global.current_floor):
		var done_label = Label.new()
		done_label.text = "All objectives unlocked, exit through the elevator"
		done_label.add_theme_color_override("font_color", Color(0, 1, 0))
		list.add_child(done_label)
