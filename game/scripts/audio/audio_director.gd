extends Node

var _player: AudioStreamPlayer
var _world: Node

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)


func gunshot(id: String, pos: Vector3) -> void:
	_play_at(pos, 0.22 if id.begins_with("wpn_kf") else 0.16, 0.9)


func empty_click() -> void:
	_play_tone(0.08, 0.35)


func reload() -> void:
	_play_tone(0.12, 0.5)


func impact(pos: Vector3) -> void:
	_play_at(pos, 0.08, 0.45)


func explosion(pos: Vector3) -> void:
	_play_at(pos, 0.4, 0.25)


func alarm() -> void:
	_play_tone(0.35, 0.4)


func radio(line: String) -> void:
	EventBus.notify.emit(line)
	_play_tone(0.1, 0.8)


func footstep(_pos: Vector3, _surface: String) -> void:
	_play_tone(0.04, 0.2)


func _play_tone(len: float, pitch: float) -> void:
	_player.stream = _tone(440.0 * pitch, len)
	_player.play()


func _play_at(pos: Vector3, len: float, pitch: float) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = _tone(180.0 * pitch, len)
	p.unit_size = 8.0
	p.max_distance = 60.0
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)


func _tone(hz: float, seconds: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var n := int(22050 * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / float(n)
		var s := int(sin(TAU * hz * i / 22050.0) * 8000.0 * env)
		data.encode_s16(i * 2, s)
	stream.data = data
	return stream
