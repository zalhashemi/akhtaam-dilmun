extends CanvasLayer

@onready var spinner = $Spinner

var target_scene: String = ""
var loading_started: bool = false

var _dot_count: int = 0
var _dot_timer: float = 0.0
var _dot_interval: float = 0.4
var _base_message: String = ""
var _elapsed: float = 0.0
var _phase: int = 0

func _ready() -> void:
	target_scene = Global.next_scene
	if target_scene == "":
		push_error("LoadingScreen: No target scene set in Global.next_scene")
		return

	var status = ResourceLoader.load_threaded_get_status(target_scene)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(target_scene)
	loading_started = true

	_base_message = "جارٍ التحميل" if Global.current_locale == "ar" else "Loading"
	spinner.label_text = _base_message + "."

func _get_phase_base() -> String:
	var is_ar := Global.current_locale == "ar"
	if _phase == 2:
		return "على وشك الانتهاء" if is_ar else "Finishing up"
	elif _phase == 1:
		return "تقريباً" if is_ar else "Almost there"
	else:
		return "جارٍ التحميل" if is_ar else "Loading"

func _process(delta: float) -> void:
	if not loading_started:
		return

	_elapsed += delta

	# Phase transitions
	if _elapsed >= 10.0 and _phase < 2:
		_phase = 2
		_base_message = _get_phase_base()
	elif _elapsed >= 5.0 and _phase < 1:
		_phase = 1
		_base_message = _get_phase_base()

	_dot_timer += delta
	if _dot_timer >= _dot_interval:
		_dot_timer = 0.0
		_dot_count = (_dot_count + 1) % 3
		spinner.label_text = _base_message + ".".repeat(_dot_count + 1)

	var status = ResourceLoader.load_threaded_get_status(target_scene)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed = ResourceLoader.load_threaded_get(target_scene)
		get_tree().change_scene_to_packed(packed)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		spinner.label_text = "خطأ في تحميل المشهد." if Global.current_locale == "ar" else "Error loading scene."
		push_error("LoadingScreen: Failed to load -> " + target_scene)
