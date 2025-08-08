extends Control

signal floor_selected(floor_index)

@onready var floor_selector = $FloorSelector
@onready var scroll_container = $FloorSelector/ScrollContainer
@onready var floor_list = $FloorSelector/ScrollContainer/FloorList

var current_floor_instance: Node = null


func _ready():
	scroll_container.visible = false
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_selector.pressed.connect(_on_floor_selector_pressed)
	_populate_floor_list()

func _on_floor_selector_pressed():
	scroll_container.visible = !scroll_container.visible
	print("Toggled floor list visibility to ", scroll_container.visible)

func _populate_floor_list():
	clear_children(floor_list)
	floor_list.add_theme_constant_override("separation", 8)
	
	for i in range(3):
		var btn = Button.new()
		btn.text = "Floor %d" % (i + 1)
		
		var captured_i = i
		
		btn.pressed.connect(func():
			print("✅ Clicked floor %d" % (captured_i + 1))
			_set_selected_floor(captured_i)
			emit_signal("floor_selected", captured_i)
			scroll_container.visible = false
		)
		
		floor_list.add_child(btn)


func _set_selected_floor(floor_index: int) -> void:
	floor_selector.text = "Floor %d" % (floor_index + 1)

func clear_children(node):
	for child in node.get_children():
		child.queue_free()
