extends Control

@onready var cards_container = $ScrollContainer/CardsContainer
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel
@onready var hire_button = $DescriptionPanel/HireButton
@onready var interview_button = $DescriptionPanel/InterviewButton
@onready var interview_popup = preload("res://InterviewPopup.tscn").instantiate()
@onready var employee_card_scene = preload("res://EmployeeCard.tscn") # The card scene now with NO script

var hire_candidates = [
	{
		"id": 1,
		"name": "Alice",
		"bio": """Summary:
A fast learner with high potential, eager to take on challenges and adapt quickly.

Skills:
- Data entry & analysis
- Team collaboration
- Time management

Experience:
- Internship at BrightFuture Inc. (3 months) – Assisted with database management and reporting.

Education:
- B.A. in Business Administration, Metro City College

Hobbies:
- Reading mystery novels
- Hiking and outdoor exploration""",
		"avatar": preload("res://Assets/Avatars/emp1.png")
	},
	{
		"id": 2,
		"name": "Bob",
		"bio": """Summary:
Loyal and reliable worker with a proven track record in administrative tasks.

Skills:
- Office organization
- Scheduling & calendar management
- Document preparation

Experience:
- Administrative Assistant at ClearPath Ltd. (2 years)
- Volunteer coordinator at Local Shelter

Education:
- High School Diploma, Northside High

Hobbies:
- Gardening
- DIY home improvement""",
		"avatar": preload("res://Assets/Avatars/emp2.png")
	},
	{
		"id": 3,
		"name": "Cleo",
		"bio": """Summary:
Creative thinker with strong communication skills and a passion for problem-solving.

Skills:
- Public speaking
- Creative writing
- Team facilitation

Experience:
- Marketing intern at Visionary Media (6 months)
- University debate team captain

Education:
- B.A. in Communications, Riverdale University

Hobbies:
- Painting
- Hosting community events""",
		"avatar": preload("res://Assets/Avatars/emp3.png")
	},
	{
		"id": 4,
		"name": "David",
		"bio": """Summary:
Experienced in marketing and sales with a focus on customer engagement and retention.

Skills:
- Lead generation
- Negotiation
- Digital marketing

Experience:
- Sales Executive at Trendify (3 years)
- Marketing Assistant at Alpha Advertising (1 year)

Education:
- B.A. in Marketing, East Coast University

Hobbies:
- Photography
- Traveling""",
		"avatar": preload("res://Assets/Avatars/emp4.png")
	},
	{
		"id": 5,
		"name": "Eva",
		"bio": """Summary:
Detail-oriented analyst with a knack for spotting patterns and improving processes.

Skills:
- Data visualization
- Financial reporting
- Process optimization

Experience:
- Junior Analyst at Apex Analytics (2 years)

Education:
- B.Sc. in Economics, Capital State University

Hobbies:
- Sudoku & puzzle solving
- Cooking new recipes""",
		"avatar": preload("res://Assets/Avatars/emp5.png")
	},
	{
		"id": 6,
		"name": "Frank",
		"bio": """Summary:
Tech-savvy problem solver with extensive troubleshooting experience.

Skills:
- Hardware repair
- Network configuration
- Customer support

Experience:
- IT Support Specialist at NetPro Systems (4 years)

Education:
- A.A.S. in Information Technology, Westbrook Tech

Hobbies:
- Building custom PCs
- Playing strategy games""",
		"avatar": preload("res://Assets/Avatars/emp6.png")
	}
]

var selected_emp_id: int = -1

func _ready():
	add_child(interview_popup)
	interview_popup.hide()
	description_panel.visible = false
	spawn_cards()
	
	hire_button.connect("pressed", Callable(self, "_on_hire_pressed"))
	interview_button.connect("pressed", Callable(self, "_on_interview_pressed"))

func spawn_cards():
	# Clear old cards
	for child in cards_container.get_children():
		child.queue_free()
	
	for emp_data in hire_candidates:
		var card = employee_card_scene.instantiate()
		
		# Set up card UI elements manually because EmployeeCard has no script:
		var name_label = card.get_node("NameLabel")
		var avatar_node = card.get_node("Avatar")
		
		if name_label:
			name_label.text = emp_data.get("name", "Unknown")
		if avatar_node and avatar_node is TextureRect:
			avatar_node.texture = emp_data.get("avatar", null)
		
		# Assign the emp_id as metadata or custom property on the card node for identification
		card.set_meta("emp_id", emp_data.get("id", -1))
		
		# Connect the card's pressed signal (Button node) to local handler with emp_id:
		card.connect("pressed", Callable(self, "_on_card_pressed").bind(emp_data.get("id", -1)))
		
		cards_container.add_child(card)

func _on_card_pressed(emp_id: int) -> void:
	selected_emp_id = emp_id
	var emp_list = hire_candidates.filter(func(e): return e["id"] == emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		description_panel.visible = true
		desc_name_label.text = emp.get("name", "Unknown")
		desc_bio_label.text = emp.get("bio", "No bio available")
		
		
func _on_hire_pressed():
	if selected_emp_id == -1:
		return
	hire_candidates = hire_candidates.filter(func(e): return e["id"] != selected_emp_id)
	spawn_cards()
	description_panel.visible = false
	selected_emp_id = -1

func _on_interview_pressed():
	if selected_emp_id == -1:
		return
	var emp_list = hire_candidates.filter(func(e): return e["id"] == selected_emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		interview_popup.set_employee(emp)
		interview_popup.popup_centered()
