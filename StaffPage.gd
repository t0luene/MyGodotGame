extends Control

# Your staff data
var staff_members = [
	{
		"id": 1,
		"name": "Alice",
		"bio": "Alice is a quick learner who adapts easily to new challenges, approaching every task with enthusiasm and dedication. She consistently delivers high-quality work and shows great initiative. Her positive attitude makes her a valuable team member who lifts those around her.",
		"avatar": preload("res://Assets/Avatars/emp1.png")
	},
	{
		"id": 2,
		"name": "Bob",
		"bio": "Bob is a dependable team player known for his strong organizational skills and calm demeanor. He excels at keeping projects on track and ensures smooth communication across departments. His reliability and attention to detail make him a backbone of the office.",
		"avatar": preload("res://Assets/Avatars/emp2.png")
	},
	{
		"id": 3,
		"name": "Cleo",
		"bio": "Cleo brings creativity and exceptional communication skills to the team. She consistently offers fresh, innovative ideas and encourages collaboration. Her passion for problem-solving and team facilitation makes her an inspiring presence in any project.",
		"avatar": preload("res://Assets/Avatars/emp3.png")
	},
	{
		"id": 4,
		"name": "David",
		"bio": "David has a strong background in marketing and sales, consistently driving growth through creative campaigns and strategic planning. His ability to understand customer needs and negotiate effectively makes him an asset to the team. He is results-oriented and highly motivated.",
		"avatar": preload("res://Assets/Avatars/emp4.png")
	},
	{
		"id": 5,
		"name": "Eva",
		"bio": "Eva is a detail-oriented analyst with a talent for spotting patterns and optimizing processes. Her data-driven approach helps improve efficiency and financial reporting. She is known for her sharp insights and commitment to accuracy in every project she undertakes.",
		"avatar": preload("res://Assets/Avatars/emp5.png")
	},
	{
		"id": 6,
		"name": "Frank",
		"bio": "Frank is a tech-savvy problem solver with extensive experience in IT support and troubleshooting. He quickly resolves complex technical issues and ensures that systems run smoothly. His expertise keeps the team’s tools reliable and the workflow uninterrupted.",
		"avatar": preload("res://Assets/Avatars/emp6.png")
	}
]


@onready var cards_container = $ScrollContainer/CardsContainer
@onready var description_panel = $DescriptionPanel
@onready var desc_name_label = $DescriptionPanel/NameLabel
@onready var desc_bio_label = $DescriptionPanel/BioLabel
@onready var fire_button = $DescriptionPanel/FireButton
@onready var promote_button = $DescriptionPanel/PromoteButton

var selected_emp_id: int = -1
var employee_card_scene = preload("res://EmployeeCard.tscn")  # Reuse your EmployeeCard scene

func _ready():
	description_panel.visible = false
	fire_button.connect("pressed", Callable(self, "_on_fire_pressed"))
	promote_button.connect("pressed", Callable(self, "_on_promote_pressed"))
	spawn_cards()

func spawn_cards():
	for child in cards_container.get_children():
		child.queue_free()
	
	for emp_data in staff_members:
		var card = employee_card_scene.instantiate()
		
		# Set labels and avatar manually
		var name_label = card.get_node("NameLabel")
		var avatar_node = card.get_node("Avatar")
		
		if name_label:
			name_label.text = emp_data.get("name", "Unknown")
		if avatar_node and avatar_node is TextureRect:
			avatar_node.texture = emp_data.get("avatar", null)
		
		# Save emp_id on card metadata to identify later
		card.set_meta("emp_id", emp_data.get("id", -1))
		
		# Connect pressed signal to a handler, passing emp_id
		card.connect("pressed", Callable(self, "_on_card_pressed").bind(emp_data.get("id", -1)))
		
		cards_container.add_child(card)

func _on_card_pressed(emp_id: int):
	selected_emp_id = emp_id
	var emp_list = staff_members.filter(func(e): return e["id"] == emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		description_panel.visible = true
		desc_name_label.text = emp.get("name", "Unknown")
		desc_bio_label.text = emp.get("bio", "No bio available")

func _on_card_selected(emp_id: int):
	selected_emp_id = emp_id
	var emp_list = staff_members.filter(func(e): return e["id"] == emp_id)
	if emp_list.size() > 0:
		var emp = emp_list[0]
		description_panel.visible = true
		desc_name_label.text = emp.get("name", "Unknown")
		desc_bio_label.text = emp.get("bio", "No bio available")

func _on_fire_pressed():
	if selected_emp_id == -1:
		return
	# Remove fired employee
	staff_members = staff_members.filter(func(e): return e["id"] != selected_emp_id)
	spawn_cards()
	description_panel.visible = false
	selected_emp_id = -1

func _on_promote_pressed():
	if selected_emp_id == -1:
		return
	# Example promote logic - you can expand this as needed
	print("Promoting employee with ID:", selected_emp_id)
	# Show a simple confirmation or effect, or update some internal data
