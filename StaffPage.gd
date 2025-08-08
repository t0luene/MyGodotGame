extends Control

var hire_candidates = [
	{"id": 1, "name": "Alice", "bio": "A fast learner with high potential.", "avatar": preload("res://Assets/Avatars/emp1.png")},
	{"id": 2, "name": "Bob", "bio": "Loyal and reliable. Great for admin tasks.", "avatar": preload("res://Assets/Avatars/emp2.png")},
	{"id": 3, "name": "Cleo", "bio": "Creative thinker with strong communication.", "avatar": preload("res://Assets/Avatars/emp3.png")},
	{"id": 4, "name": "David", "bio": "Experienced in marketing and sales.", "avatar": preload("res://Assets/Avatars/emp4.png")},
	{"id": 5, "name": "Eva", "bio": "Detail-oriented with strong analytical skills.", "avatar": preload("res://Assets/Avatars/emp5.png")},
	{"id": 6, "name": "Frank", "bio": "Tech-savvy and excellent at troubleshooting.", "avatar": preload("res://Assets/Avatars/emp6.png")},
]

@onready var cards_container = $ScrollContainer/CardsContainer  # your new container node
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel

func _ready():
	print("desc_name_label:", desc_name_label)
	print("desc_bio_label:", desc_bio_label)
	description_panel.visible = false
	spawn_cards()

func spawn_cards():
	for emp_data in hire_candidates:
		print("[HiringPage] Spawning card for", emp_data.get("name"), "with avatar:", emp_data.get("avatar"))
		var card = preload("res://EmployeeCard.tscn").instantiate()
		card.set_employee_data(emp_data)
		card.card_selected.connect(_on_card_selected)
		cards_container.add_child(card)
		print("[HiringPage] Added card to container:", cards_container.name)

func _on_card_selected(emp_id: int):
	print("[HiringPage] Card selected for emp_id:", emp_id)
	var emp = hire_candidates.filter(func(e): return e["id"] == emp_id)[0]
	if emp:
		print("[HiringPage] Setting description for employee:", emp.get("name"))
		print("[HiringPage] desc_name_label before set:", desc_name_label.text)
		print("[HiringPage] desc_bio_label before set:", desc_bio_label.text)
		description_panel.visible = true
		desc_name_label.text = emp.get("name", "Unknown")
		desc_bio_label.text = emp.get("bio", "No bio available")
		print("[HiringPage] desc_name_label after set:", desc_name_label.text)
		print("[HiringPage] desc_bio_label after set:", desc_bio_label.text)
