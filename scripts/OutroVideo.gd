extends Node

const GAME_END_SCENE := "res://scenes/GameEndScreen.tscn"

var _going := false
var _vp: VideoStreamPlayer = null

func _ready() -> void:
	var is_ar := Global.current_locale == "ar"

	# Pre-load the end screen while the video plays
	ResourceLoader.load_threaded_request(GAME_END_SCENE)

	var canvas := CanvasLayer.new()
	canvas.layer = 0
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left   = 0.0
	bg.offset_top    = 0.0
	bg.offset_right  = 0.0
	bg.offset_bottom = 0.0
	bg.layout_mode   = 1
	bg.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	# Try .ogv first (Ogg Theora), then .mp4 as fallback
	var base_name: String = "arabicOutroVid" if is_ar else "englishOutroVid"
	var ogv_path := "res://assets/animations/" + base_name + ".ogv"
	var mp4_path := "res://assets/animations/" + base_name + ".mp4"

	var stream = load(ogv_path)
	if stream == null:
		stream = load(mp4_path)

	if stream != null:
		_vp = VideoStreamPlayer.new()
		_vp.set_anchors_preset(Control.PRESET_FULL_RECT)
		_vp.offset_left   = 0.0
		_vp.offset_top    = 0.0
		_vp.offset_right  = 0.0
		_vp.offset_bottom = 0.0
		_vp.layout_mode   = 1
		_vp.expand        = true
		_vp.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_vp.stream        = stream
		canvas.add_child(_vp)

		var skip_btn := _make_skip_button(is_ar)
		canvas.add_child(skip_btn)

		MusicManager.pause_music()
		_vp.play()
		_vp.finished.connect(_go_to_end_screen)
	else:
		push_error(
			"OutroVideo: Could not load video. Godot 4 requires .ogv (Ogg Theora).\n" +
			"Convert with: ffmpeg -i " + base_name + ".mp4 -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 " + base_name + ".ogv"
		)
		await get_tree().create_timer(0.5).timeout
		_go_to_end_screen()


func _make_skip_button(is_ar: bool) -> Button:
	var btn := Button.new()
	btn.text = "\u062A\u062E\u0637\u064A \u25C4" if is_ar else "Skip \u25BA"
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
	if is_ar and Global.arabic_font != null:
		btn.add_theme_font_override("font", Global.arabic_font)
		btn.text_direction = Control.TEXT_DIRECTION_RTL
	btn.custom_minimum_size = Vector2(120, 44)
	btn.anchor_left   = 1.0
	btn.anchor_top    = 1.0
	btn.anchor_right  = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left   = -150.0
	btn.offset_top    = -64.0
	btn.offset_right  = -20.0
	btn.offset_bottom = -20.0
	btn.layout_mode   = 1
	btn.pressed.connect(_go_to_end_screen)
	return btn


func _unhandled_input(event: InputEvent) -> void:
	if _vp == null or not _vp.is_playing():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
			_go_to_end_screen()


func _go_to_end_screen() -> void:
	if _going:
		return
	_going = true
	if _vp != null and _vp.is_playing():
		_vp.stop()
	MusicManager.resume_music()

	var status := ResourceLoader.load_threaded_get_status(GAME_END_SCENE)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(GAME_END_SCENE)
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(GAME_END_SCENE)
