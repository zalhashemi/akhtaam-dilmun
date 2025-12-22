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

	# start countdown
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_timeout)
	countdown_timer.start()


func update_counter():
	counter.text = str(collected_pearls) + "/" + str(total_pearls)


func update_timer_label():
	timer_label.text = str(time_left) + "s"


func on_pearl_collected():
	if ended:
		return

	collected_pearls += 1
	update_counter()

	# success condition
	if collected_pearls >= total_pearls:
		quest_completed()


func _on_countdown_timeout():
	if ended:
		return

	time_left -= 1
	if time_left < 0:
		time_left = 0

	update_timer_label()

	# fail condition
	if time_left <= 0 and collected_pearls < total_pearls:
		quest_failed()


func quest_failed():
	ended = true
	countdown_timer.stop()

	title_label.text = "Quest Failed"
	subtitle_label.text = "You collected %s/%s pearls." % [collected_pearls, total_pearls]

	end_screen.visible = true
	retry_button.visible = true
	if is_instance_valid(continue_button):
		continue_button.visible = false

	# stop gameplay input if you want:
	get_tree().paused = true
	end_screen.process_mode = Node.PROCESS_MODE_ALWAYS


func quest_completed():
	ended = true
	countdown_timer.stop()

	title_label.text = "Quest Completed"
	subtitle_label.text = "All pearls collected!"

	end_screen.visible = true
	retry_button.visible = false
	if is_instance_valid(continue_button):
		continue_button.visible = true

	get_tree().paused = true
	end_screen.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_retry_button_pressed():
	# unpause and reload scene
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_continue_button_pressed():
	# optional: unpause and go back to main map, or next dialogue scene
	get_tree().paused = false
	# Example:
	# get_tree().change_scene_to_file("res://scenes/MainMap.tscn")
