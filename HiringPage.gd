extends Control

var hire_candidates = [
	{"id": 1, "name": "Alice", "bio": "A fast learner with high potential.", "avatar": preload("res://Assets/Avatars/emp1.png")},
	{"id": 2, "name": "Bob", "bio": "Loyal and reliable. Great for admin tasks.", "avatar": preload("res://Assets/Avatars/emp2.png")},
	{"id": 3, "name": "Cleo", "bio": "Creative thinker with strong communication.", "avatar": preload("res://Assets/Avatars/emp3.png")},
	{"id": 4, "name": "David", "bio": "Experienced in marketing and sales.", "avatar": preload("res://Assets/Avatars/emp4.png")},
	{"id": 5, "name": "Eva", "bio": "Detail-oriented with strong analytical skills.", "avatar": preload("res://Assets/Avatars/emp5.png")},
	{"id": 6, "name": "Frank", "bio": "Tech-savvy and excellent at troubleshooting.", "avatar": preload("res://Assets/Avatars/emp6.png")},
]

@onready var cards_container = $ScrollContainer/CardsContainer
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel
@onready var hire_button = $DescriptionPanel/HireButton
@onready var interview_button = $DescriptionPanel/InterviewButton
@onready var interview_popup = preload("res://InterviewPopup.tscn").instantiate()
@onready var employee_card_scene = preload("res://EmployeeCard.tscn")

signal card_selected(emp_id)

var emp_id: int = -1
var selected_emp_id: int = -1

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_selected.emit(emp_id)

func _ready():
	add_child(interview_popup)
	interview_popup.hide()
	description_panel.visible = false
	spawn_cards()
	
	hire_button.connect("pressed", Callable(self, "_on_hire_pressed"))
	interview_button.connect("pressed", Callable(self, "_on_interview_pressed"))


func spawn_cards():
	for child in cards_container.get_children():
		child.queue_free()

	for emp_data in hire_candidates:
		var card = employee_card_scene.instantiate()
		card.set_employee_data(emp_data) # THIS LINE IS ESSENTIAL

		var avatar_res = emp_data.get("avatar")
		print("Loading employee:", emp_data.get("name"), "with avatar path:", avatar_res)
		if avatar_res is Texture2D:
			print("Avatar texture is valid. Size:", avatar_res.get_size())
		else:
			print("Avatar is NOT a Texture2D!")

		card.card_selected.connect(_on_card_selected)
		cards_container.add_child(card)


func _on_card_selected(emp_id: int):
	selected_emp_id = emp_id
	var emp = hire_candidates.filter(func(e): return e["id"] == emp_id)[0]
	if emp:
		description_panel.visible = true
		desc_name_label.text = emp.get("name", "Unknown")
		desc_bio_label.text = emp.get("bio", "No bio available")

func _on_hire_pressed():
	if selected_emp_id == -1:
		return
	# Remove hired employee from the list
	hire_candidates = hire_candidates.filter(func(e): return e["id"] != selected_emp_id)
	
	# Refresh the cards list so the hired employee disappears
	spawn_cards()
	
	# Hide description panel and reset selection
	description_panel.visible = false
	selected_emp_id = -1

func _on_interview_pressed():
	if selected_emp_id == -1:
		return
	var emp = hire_candidates.filter(func(e): return e["id"] == selected_emp_id)[0]
	if emp:
		interview_popup.set_employee(emp)
		interview_popup.popup_centered()  # or use .show() if not using PopupPanel

	if selected_emp_id == -1:
		return
	print("Interviewing employee ID:", selected_emp_id)
	# You can add more logic here for interviews
