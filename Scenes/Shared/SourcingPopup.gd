extends Popup
signal role_selected(role: String)

func _ready():
	$VBoxContainer/EngineerButton.connect("pressed", Callable(self, "_on_role_pressed").bind("Engineer"))
	$VBoxContainer/HRButton.connect("pressed", Callable(self, "_on_role_pressed").bind("HR"))
	$VBoxContainer/MaintenanceButton.connect("pressed", Callable(self, "_on_role_pressed").bind("Maintenance"))
	$CloseButton.connect("pressed", Callable(self, "hide"))

func _on_role_pressed(role: String):
	emit_signal("role_selected", role)
	hide()
