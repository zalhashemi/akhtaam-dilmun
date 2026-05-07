extends Node

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load("res://assets/bgMusic.ogg")
	stream.loop = true
	_player.stream = stream
	add_child(_player)
	_player.play()


func pause_music() -> void:
	if _player.playing and not _player.stream_paused:
		_player.stream_paused = true


func resume_music() -> void:
	if _player.stream_paused:
		_player.stream_paused = false
	elif not _player.playing:
		_player.play()
