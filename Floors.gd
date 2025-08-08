extends Control  # or Control, depending on your scene

var floor_number: int = 0

func set_floor_number(floor_num: int) -> void:
	floor_number = floor_num
	if has_node("ColorRect"):
		var bg = $ColorRect
		var hue = float(floor_number % 10) / 10.0
		bg.color = Color.from_hsv(hue, 0.8, 0.8)
	
	if has_node("FloorNumberLabel"):
		$FloorNumberLabel.text = "Floor %d" % floor_number
