extends Node2D

@onready var box = $Box  # reference to your Box node

func _ready():
	box.inspected.connect(_on_box_inspected)

func _on_box_inspected(_box):
	# ✅ Update quest state through Global
	Global.mark_completed("floor4", "room2")
	print("Room2 objective complete!")
