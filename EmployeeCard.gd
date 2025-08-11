extends Button

signal card_selected(emp_id: int)

@onready var avatar = $Avatar
@onready var name_label = $NameLabel

var emp_id: int = -1

func _ready():
	print("EmployeeCard _ready called for emp_id:", emp_id, "name_label:", name_label.text, "avatar.texture:", avatar.texture)


func set_employee_data(data: Dictionary):
	emp_id = data.get("id", -1)
	print("Setting employee card for:", data.get("name", "Unknown"))
	
	if name_label:
		name_label.text = data.get("name", "Unknown")
		print("Name label updated to:", name_label.text)
		
	if avatar:
		var tex = data.get("avatar", null)
		if tex is Texture2D:
			avatar.texture = tex
			print("Avatar texture set to:", tex)
			if avatar.texture:
				print("[EmployeeCard] Avatar texture size:", avatar.texture.get_size())
			else:
				print("[EmployeeCard] Avatar texture is null!")

func _pressed():
	print("[EmployeeCard] Button pressed for emp_id:", emp_id)
	card_selected.emit(emp_id)
