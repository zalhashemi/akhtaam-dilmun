extends Node2D

const _InstructionPanel = preload("res://scripts/InstructionPanel.gd")

@export var time_limit := 120
var total_pearls := 0
var collected_pearls := 0
var time_left := 0
var ended := false

@onready var counter: Label = $UI/PearlCounter
@onready var timer_label: Label = $UI/TimerLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var result_panel: CanvasLayer = $QuestResultPanel

func _ready():
	add_to_group("quest3_game")
	total_pearls = $Pearls.get_child_count()
	collected_pearls = 0
	ended = false
	time_left = time_limit
	counter.add_theme_font_size_override("font_size", 30)
	timer_label.add_theme_font_size_override("font_size", 30)
	_apply_arabic_font_to_ui()
	update_counter()
	update_timer_label()
	result_panel.retry_pressed.connect(_on_retry)
	result_panel.exit_pressed.connect(_on_exit)
	result_panel.continue_pressed.connect(_on_continue)
	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	if not countdown_timer.timeout.is_connected(Callable(self, "_on_countdown_timeout")):
		countdown_timer.timeout.connect(Callable(self, "_on_countdown_timeout"))
	counter.visible = false
	timer_label.visible = false
	var _input_overlay: Node = load("res://scripts/InputHintOverlay.gd").new()
	_input_overlay.setup("arrow_keys")
	add_child(_input_overlay)
	_start_onboarding()


func _start_onboarding() -> void:
	var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
	tut.setup([
		{
			"en": "This is your boat! Use the Arrow Keys (or W/A/S/D) to sail it.",
			"ar": "\u0647\u0630\u0647 \u0633\u0641\u064a\u0646\u062a\u0643! \u0627\u0633\u062a\u062e\u062f\u0645 \u0645\u0641\u0627\u062a\u064a\u062d \u0627\u0644\u0623\u0633\u0647\u0645 \u0644\u0644\u0625\u0628\u062d\u0627\u0631.",
			"target": Vector2(0.5, 0.52),
			"align": "top"
		},
		{
			"en": "Sail over the pearls to collect them. Get them all!",
			"ar": "\u0645\u064f\u0631\u0651 \u0641\u0648\u0642 \u0627\u0644\u0644\u0624\u0644\u0624 \u0628\u0633\u0641\u064a\u0646\u062a\u0643 \u0644\u062c\u0645\u0639\u0647. \u0627\u062c\u0645\u0639 \u0643\u0644 \u062d\u0628\u0629!",
			"target": Vector2(0.28, 0.35),
			"align": "bottom"
		},
		{
			"en": "You have 2 minutes. Don't let the timer reach 00:00!",
			"ar": "\u0644\u062f\u064a\u0643 \u062f\u0642\u064a\u0642\u062a\u0627\u0646. \u0644\u0627 \u062a\u062f\u0639 \u0627\u0644\u0645\u0624\u0642\u062a \u064a\u0635\u0644 \u0625\u0644\u0649 00:00!",
			"target": Vector2(0.13, 0.07),
			"align": "bottom"
		},
	])
	tut.tutorial_done.connect(func():
		counter.visible     = true
		timer_label.visible = true
		countdown_timer.start()
	)
	add_child(tut)

func update_counter():
	if Global.current_locale == "ar":
		var raw := "%d/%d" % [collected_pearls, total_pearls]
		counter.text = TextServerManager.get_primary_interface().format_number(raw)
	else:
		counter.text = "%d/%d" % [collected_pearls, total_pearls]

func update_timer_label():
	var minutes := time_left / 60
	var seconds := time_left % 60
	var formatted := "%02d:%02d" % [minutes, seconds]
	if Global.current_locale == "ar":
		timer_label.text = TextServerManager.get_primary_interface().format_number(formatted)
	else:
		timer_label.text = formatted

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

	var is_ar := Global.current_locale == "ar"
	var msg: String
	if is_ar:
		var ts := TextServerManager.get_primary_interface()
		var c := ts.format_number("%d" % collected_pearls)
		var t := ts.format_number("%d" % total_pearls)
		msg = "جمعت %s/%s لؤلؤة." % [c, t]
	else:
		msg = "You collected %d/%d pearls." % [collected_pearls, total_pearls]

	var title := "فشلت المهمة" if is_ar else "Quest Failed!"
	result_panel.show_failure(title + "\n" + msg)

func quest_completed():
	if ended:
		return
	ended = true
	countdown_timer.stop()
	Global.complete_quest(3)
	result_panel.show_success(tr("QUEST_COMPLETED_ALT") + "\n" + tr("Q3_ALL_COLLECTED"))

func _on_retry() -> void:
	get_tree().reload_current_scene()

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_exit() -> void:
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var text_nodes: Array = [
		$UI/PearlCounter,
		$UI/TimerLabel,
	]
	for node in text_nodes:
		if node != null and is_instance_valid(node):
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", 30 + Global.ARABIC_SIZE_BONUS)
			if node is Label:
				node.text_direction = Control.TEXT_DIRECTION_RTL
