extends Window

@onready var cards_container = $ScrollContainer/CardsContainer
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel
@onready var hire_button = $DescriptionPanel/HireButton
@onready var interview_button = $DescriptionPanel/InterviewButton
@onready var interview_popup = preload("res://InterviewPopup.tscn").instantiate()
@onready var employee_card_scene = preload("res://EmployeeCard.tscn") # The card scene with NO script

# Only 2 employees available to hire (HR + Maintenance)
var hire_candidates = [
	{
		"id": 1,
		"name": "Alice",
		"role": "HR",
		"bio": """Summary:
A fast learner with a knack for organization.

Skills:
- HR coordination
- Communication
- Scheduling

Experience:
- HR Assistant at BrightFuture Inc. (2 years)

Education:
- B.A. in Business Administration, Metro City College

Hobbies:
- Reading mystery novels
- Hiking""",
		"avatar": preload("res://Assets/Avatars/emp1.png")
	},
	{
		"id": 2,
		"name": "Bob",
		"role": "Maintenance",
		"bio": """Summary:
Reliable worker who keeps things running.

Skills:
- Electrical repairs
- Plumbing
- Preventative maintenance

Experience:
- Maintenance Tech at ClearPath Ltd. (3 years)

Education:
- High School Diploma, Northside High

Hobbies:
- Gardening
- DIY home improvement""",
		"avatar": preload("res://Assets/Avatars/emp2.png")
	}
]

var selected_emp_id: int = -1

func _ready():
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)  # 80% of the screen
	add_child(interview_popup)
	interview_popup.hide()
	description_panel.visible = false
	hire_button.disabled = true  # disabled until a card is selected
	
	spawn_cards()
	
	hire_button.connect("pressed", Callable(self, "_on_hire_pressed"))
	interview_button.connect("pressed", Callable(self, "_on_interview_pressed"))

func spawn_cards():
	var container = $ScrollContainer/CardsContainer
	
	# Clear old cards
	for child in container.get_children():
		child.queue_free()
	
	# Spawn new cards
	for emp_data in hire_candidates:
		# Skip if already hired
		if Global.hired_employees.has(emp_data):
			continue
		
		var card = employee_card_scene.instantiate()
		
		# Set UI elements
		var name_label = card.get_node("NameLabel")
		if name_label:
			name_label.text = emp_data.get("name", "Unknown")

		var role_label = card.get_node("RoleLabel")
		if role_label:
			role_label.text = emp_data.get("role", "Unknown")

		var avatar_node = card.get_node("Avatar")
		if avatar_node:
			avatar_node.texture = emp_data.get("avatar", null)

		var proficiency_label = card.get_node("ProficiencyLabel")
		if proficiency_label:
			proficiency_label.text = str(emp_data.get("proficiency", "N/A"))

		var cost_label = card.get_node("CostLabel")
		if cost_label:
			cost_label.text = str(emp_data.get("cost", 0))

		# Connect the pressed signal
		card.connect("pressed", Callable(self, "_on_card_pressed").bind(emp_data.get("id", -1)))

		# Add card to container
		container.add_child(card)

		# Add card to container
		container.add_child(card)


func _on_close_requested():
	queue_free()

func _on_card_pressed(emp_id: int) -> void:
	selected_emp_id = emp_id
	var emp_list = hire_candidates.filter(func(e): return e["id"] == emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		description_panel.visible = true
		desc_name_label.text = emp.get("name", "Unknown")
		desc_bio_label.text = emp.get("bio", "No bio available")
		hire_button.disabled = false

func _on_hire_pressed():
	if selected_emp_id == -1:
		return
	var emp_list = hire_candidates.filter(func(e): return e["id"] == selected_emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		# Save employee into global state
		Global.hired_employees.append(emp)
		print("Hired:", emp["name"], "Role:", emp["role"])
	
	# Remove from available candidates
	hire_candidates = hire_candidates.filter(func(e): return e["id"] != selected_emp_id)
	spawn_cards()
	
	# Reset selection
	description_panel.visible = false
	hire_button.disabled = true
	selected_emp_id = -1


func _on_interview_pressed():
	if selected_emp_id == -1:
		return
	var emp_list = hire_candidates.filter(func(e): return e["id"] == selected_emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		interview_popup.set_employee(emp)
		interview_popup.popup_centered()
