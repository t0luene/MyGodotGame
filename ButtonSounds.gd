extends Node

@onready var click_sound = preload("res://Assets/Audio/Sounds/switch34.ogg")

func _ready():
	print("🍕 ButtonSounds.gd loaded!")

	# Connect to all existing buttons now
	_connect_existing_buttons(get_tree().root)

	# Also connect to any future buttons added
	get_tree().connect("node_added", _on_node_added)

func _connect_existing_buttons(node):
	if node is Button:
		_connect_button(node)
	for child in node.get_children():
		_connect_existing_buttons(child)

func _on_node_added(node):
	if node is Button:
		_connect_button(node)

func _connect_button(button: Button):
	if not button.is_connected("pressed", Callable(self, "_play_click")):
		button.pressed.connect(_play_click.bind(button))

func _play_click(button: Button):
	if button.has_meta("no_click_sound"):
		return

	var player = AudioStreamPlayer.new()
	player.stream = click_sound
	get_tree().root.add_child(player)
	player.play()

	# Free the player after the sound finishes
	var sound_length = player.stream.get_length()
	get_tree().create_timer(sound_length).timeout.connect(player.queue_free)
