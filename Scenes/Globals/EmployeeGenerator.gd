# EmployeeGenerator.gd
extends Node

const Employee = preload("res://Scenes/Shared/Employee.gd")

# Avatars
var avatars: Array[Texture2D] = [
	preload("res://Assets/Avatars/emp1.png"),
	preload("res://Assets/Avatars/emp2.png"),
	preload("res://Assets/Avatars/emp3.png"),
	preload("res://Assets/Avatars/emp4.png"),
	preload("res://Assets/Avatars/emp5.png"),
	preload("res://Assets/Avatars/emp6.png")
]

# Roles
var roles: Array = ["HR", "Maintenance", "Engineer"]

# Cat names
var names: Array = ["Whiskers", "Mittens", "Shadow", "Luna", "Tiger", "Simba", "Cleo", "Ginger", "Salem", "Paws"]

# Bio fragments
var intros: Array = [
	"A quick learner with high curiosity and adaptability.",
	"Reliable and precise, never misses a task.",
	"Creative thinker, always innovating new approaches.",
	"Friendly and approachable, loves teamwork.",
	"Detail-oriented and analytical, enjoys solving puzzles."
]

var skills: Array = [
	"Data entry & analysis, Team collaboration, Time management",
	"Electrical repairs, Plumbing, Preventative maintenance",
	"Coding, Debugging, Software design",
	"Graphic design, UX/UI, Branding",
	"Customer support, Communication, Scheduling"
]

var experiences: Array = [
	"Internship at BrightFuture Inc.",
	"3 years at ClearPath Ltd.",
	"Junior developer at TechNova",
	"Assistant designer at PixelWorks",
	"Customer support at ServicePlus"
]

var educations: Array = [
	"B.A. in Business Administration, Metro City College",
	"High School Diploma, Northside High",
	"B.Sc. in Computer Science, City University",
	"Associate Degree in Design, Art Academy",
	"Vocational Training in Maintenance, Tech Institute"
]

var hobbies: Array = [
	"Chasing laser pointers, Exploring high places",
	"Napping in sunbeams, Bird watching",
	"Playing with yarn, Solving puzzle toys",
	"Sketching in catnip gardens, Traveling on adventures",
	"Cuddling with humans, Helping in small tasks"
]

# Keep track of used combinations to avoid duplicates
var used_combinations: Array[Dictionary] = []

func generate_employee(next_employee_id: int) -> Employee:
	var emp = Employee.new()
	emp.id = next_employee_id
	emp.level = 1  # start at level 1

	# Random selections
	emp.role = roles[randi() % roles.size()]
	emp.avatar = avatars[randi() % avatars.size()]
	emp.proficiency = randi() % 6  # 0-5
	emp.cost = 50 + emp.proficiency * 20

	# Pick bio sections
	var intro = intros[randi() % intros.size()]
	var skill = skills[randi() % skills.size()]
	var exp = experiences[randi() % experiences.size()]
	var edu = educations[randi() % educations.size()]
	var hobby = hobbies[randi() % hobbies.size()]

	emp.bio = "Intro: " + intro + "\nSkills: " + skill + "\nExperience: " + exp + "\nEducation: " + edu + "\nHobbies: " + hobby

	# Assign a random cat name (unique)
	var attempts = 0
	while attempts < 10:
		var name_choice = names[randi() % names.size()]
		if not used_combinations.has({"name": name_choice}):
			emp.name = name_choice
			break
		attempts += 1
	if emp.name == "":
		emp.name = "Cat_" + str(next_employee_id)  # fallback

	# Ensure uniqueness (check role + bio)
	while is_duplicate(emp):
		emp.role = roles[randi() % roles.size()]
		emp.avatar = avatars[randi() % avatars.size()]
		emp.proficiency = randi() % 6
		emp.cost = 50 + emp.proficiency * 20
		intro = intros[randi() % intros.size()]
		skill = skills[randi() % skills.size()]
		exp = experiences[randi() % experiences.size()]
		edu = educations[randi() % educations.size()]
		hobby = hobbies[randi() % hobbies.size()]
		emp.bio = "Intro: " + intro + "\nSkills: " + skill + "\nExperience: " + exp + "\nEducation: " + edu + "\nHobbies: " + hobby

	# Record combination
	used_combinations.append({
		"name": emp.name,
		"role": emp.role,
		"bio_intro": intro
	})

	return emp

func is_duplicate(emp: Employee) -> bool:
	for comb in used_combinations:
		if comb.name == emp.name and comb.role == emp.role and comb.bio.find(comb.bio_intro) != -1:
			return true
	return false
