extends Node2D

@export var time_limit := 40

var total_pearls := 0
var collected_pearls := 0
var time_left := 0
var ended := false

@onready var counter: Label = $UI/PearlCounter
@onready var timer_label: Label = $UI/TimerLabel

@onready var end_screen: Control = $UI/EndScreen
@onready var title_label: Label = $UI/EndScreen/TitleLabel
@onready var subtitle_label: Label = $UI/EndScreen/SubtitleLabel
@onready var retry_button: Button = $UI/EndScreen/Buttons/RetryButton
@onready var continue_button: Button = $UI/EndScreen/Buttons/ContinueButton # optional

@onready var countdown_timer: Timer = $CountdownTimer


func _ready():
	add_to_group("quest3_game")

	total_pearls = $Pearls.get_child_count()
	collected_pearls = 0
	ended = false

	time_left = time_limit
	update_counter()
	update_timer_label()

	end_screen.visible = false
	retry_button.visible = false
	if is_instance_valid(continue_button):
		continue_button.visible = false

	var cb_retry := Callable(self, "_on_retry_button_pressed")
	if not retry_button.pressed.is_connected(cb_retry):
		retry_button.pressed.connect(cb_retry)

	if is_instance_valid(continue_button):
		var cb_cont := Callable(self, "_on_continue_button_pressed")
		if not continue_button.pressed.is_connected(cb_cont):
			continue_button.pressed.connect(cb_cont)

	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	if not countdown_timer.timeout.is_connected(Callable(self, "_on_countdown_timeout")):
		countdown_timer.timeout.connect(Callable(self, "_on_countdown_timeout"))
	countdown_timer.start()


func update_counter():
	counter.text = "%d/%d" % [collected_pearls, total_pearls]


func update_timer_label():
	timer_label.text = "%ds" % time_left


func on_pearl_collected():
	if ended:
		return

	collected_pearls += 1
	update_counter()

	if collected_pearls >= total_pearls:
		quest_completed()


func _on_countdown_timeout():
	if ended:
		return

	time_left -= 1
	if time_left < 0:
		time_left = 0

	update_timer_label()

	if time_left <= 0 and collected_pearls < total_pearls:
		quest_failed()


func quest_failed():
	if ended:
		return

	ended = true
	countdown_timer.stop()

	title_label.text = tr("QUEST_FAILED")
	subtitle_label.text = tr("Q3_PEARLS_COLLECTED") % [collected_pearls, total_pearls]

	end_screen.visible = true
	retry_button.visible = true
	if is_instance_valid(continue_button):
		continue_button.visible = false


func quest_completed():
	if ended:
		return

	ended = true
	countdown_timer.stop()

	title_label.text = tr("QUEST_COMPLETED_ALT")
	subtitle_label.text = tr("Q3_ALL_COLLECTED")

	end_screen.visible = true
	retry_button.visible = false
	if is_instance_valid(continue_button):
		continue_button.visible = false

	Global.complete_quest(3)

	await get_tree().create_timer(1.2).timeout
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_retry_button_pressed():
	# No pausing used here, just reload
	get_tree().reload_current_scene()


func _on_continue_button_pressed():
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
