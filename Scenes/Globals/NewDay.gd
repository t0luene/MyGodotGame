extends Window  # Or Node2D depending on your root

@onready var day_label = $HUD/DayLabel
@onready var work_button = $HUD/VBoxContainer/WorkButton
@onready var daily_newspaper_scene = preload("res://DailyNewspaper.tscn") # adjust path if needed

# Game variables
var last_day_base_income := 0
var last_day_employee_income := 0

func update_hud():
	$HUD/MoneyLabel.text = str(Global.money)

var current_floor_instance: Node = null

func _ready():
	# Popup behavior
	close_requested.connect(_on_close_requested)
	popup_centered_ratio(0.8)

	print("MainPage ready!")

	# Listen for money changes
	Global.connect("money_changed", Callable(self, "_on_money_changed"))

	# Initialize UI
	update_ui()
	update_hud()
	
func _on_close_requested():
	queue_free()

func _on_money_changed(new_money):
	update_ui()
	
func update_ui():
	$HUD/MoneyLabel.text = "Money: $" + str(Global.money)
	$HUD/DayLabel.text = "Day: " + str(Global.day)
	$HUD/VBoxContainer/MoneyLabel.text = "Money: $" + str(Global.money)
	$HUD/VBoxContainer/TimeLabel.text = "Time: Day " + str(Global.day)

var current_newspaper = null

func some_update_function():
	Global.money += 100

# Daily Report UI
func show_daily_report():
	print("show_daily_report() called")
	var report_title = "S Tier Work Day"  # You can make this dynamic later
	var total_profit = last_day_base_income + last_day_employee_income
	var breakdown_text = "Total Profit: $" + str(total_profit) + "\n"
	breakdown_text += "- Base Operations: $" + str(last_day_base_income) + "\n"
	breakdown_text += "- Employee Impact: $" + str(last_day_employee_income)
	$HUD/DailyReport/VBoxContainer/TitleLabel.text = report_title
	$HUD/DailyReport/VBoxContainer/BreakdownLabel.text = breakdown_text
	$HUD/DailyReport.visible = true
	print("DailyReport visible set to true")

func _on_close_button_pressed() -> void:
	$HUD/DailyReport.visible = false
	if current_newspaper != null:
		current_newspaper.queue_free()
		current_newspaper = null

func _on_work_button_pressed() -> void:
	Fade.fade_out(0.5)               # start fade out
	await get_tree().create_timer(0.5).timeout  # ⏸️ wait half a second
	show_daily_newspaper()
	await get_tree().create_timer(0.5).timeout  # ⏸️ wait before fading in
	Fade.fade_in(0.5)
	next_day()  # advance the day

func show_daily_newspaper() -> void:
	if current_newspaper != null:
		current_newspaper.queue_free()

	current_newspaper = daily_newspaper_scene.instantiate()
	$HUD.add_child(current_newspaper)  # add to HUD, not root
	current_newspaper.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Move newspaper to top inside HUD to appear above black overlay and DailyReport
	$HUD.move_child(current_newspaper, $HUD.get_child_count() - 1)
	print("Children order inside HUD:")
	for i in range($HUD.get_child_count()):
		print(i, ":", $HUD.get_child(i).name)

func next_day():
	print("next_day() called from:", get_stack())
	Global.day += 1
	print("📅 Day advanced to: ", Global.day)

	# Update UI
	update_ui()

	# Quest7 progression: complete "new_day" requirement on Day 2
	if Global.day == 2 and QuestManager.current_quest_id == 7:
		QuestManager.quest7_new_day()

	# Show daily report after Day 1
	if Global.day > 1:
		show_daily_report()


func calculate_daily_income():
	var income = 25  # Base income each day
	for emp in Global.hired_employees:
		income += emp.boost
	return income
	
func clear_children(node):
	for child in node.get_children():
		child.queue_free()
