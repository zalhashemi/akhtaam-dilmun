extends Node2D

@onready var ui_label: Label = $UI/Label
@onready var shards_holder: Node = $Shards

@onready var timer_label: Label = $UI/TimerLabel
@onready var countdown_timer: Timer = $CountdownTimer

@onready var result_panel: Control = $UI/ResultPanel
@onready var result_title: Label = $UI/ResultPanel/VBoxContainer/ResultTitle
@onready var result_body: Label = $UI/ResultPanel/VBoxContainer/ResultBody
@onready var retry_button: Button = $UI/ResultPanel/VBoxContainer/RetryButton

var finished := false


func _ready():
	ui_label.text = "From the ruins of Tylos, this is a Lagynos Pottery. 
It was used for serving and pouring drinks at gatherings.
"

	result_panel.visible = false
	retry_button.visible = false

	# Timer setup
	countdown_timer.wait_time = 60.0
	countdown_timer.one_shot = true
	countdown_timer.start()
	countdown_timer.timeout.connect(_on_timer_timeout)

	retry_button.pressed.connect(_on_retry_pressed)

	_update_timer_label()


func _process(_delta):
	if finished:
		return
	_update_timer_label()


func _update_timer_label():
	var remaining := int(ceil(countdown_timer.time_left))
	var minutes := remaining / 60
	var seconds := remaining % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _check_puzzle_complete():
	if finished:
		return

	for shard in shards_holder.get_children():
		if shard is Area2D and not shard.placed_correctly:
			return

	_on_puzzle_complete()


func _on_puzzle_complete():
	finished = true
	countdown_timer.stop()
	timer_label.visible = false

	result_panel.visible = true
	result_title.text = "Quest Completed"
	result_body.text = ""
	retry_button.visible = false

	Global.seal_count += 1
	Global.completed_quests["quest2"] = true

	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")


func _on_timer_timeout():
	if finished:
		return

	finished = true
	timer_label.visible = false

	result_panel.visible = true
	result_title.text = "Quest Failed"
	result_body.text = "Try again!"
	retry_button.visible = true


func _on_retry_pressed():
	get_tree().reload_current_scene()
