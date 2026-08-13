extends CanvasLayer

signal started

var _quality: int = 1 # High=0 Medium=1 Low=2

func _ready() -> void:
	layer = 100
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.08, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var title := Label.new()
	title.text = "FURY FRONT"
	title.position = Vector2(640, 220)
	title.size = Vector2(640, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.91, 0.64, 0.09))
	add_child(title)
	var sub := Label.new()
	sub.text = "PC WEB  ·  OPERATION: BROKEN PERIMETER  ·  IRONFALL DEPOT"
	sub.position = Vector2(460, 300)
	sub.size = Vector2(1000, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	add_child(sub)
	var hint := Label.new()
	hint.text = "WASD move  ·  Mouse look  ·  LMB fire  ·  RMB ADS  ·  R reload  ·  Shift sprint  ·  C crouch  ·  Space jump  ·  E interact"
	hint.position = Vector2(160, 360)
	hint.size = Vector2(1600, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.73, 0.76))
	add_child(hint)
	_quality_row()
	var start := Button.new()
	start.text = "START OPERATION"
	start.position = Vector2(760, 560)
	start.size = Vector2(400, 72)
	start.pressed.connect(_start)
	add_child(start)
	start.grab_focus()
	var note := Label.new()
	note.text = "Click starts audio and mouse capture (browser requirement)."
	note.position = Vector2(560, 650)
	note.size = Vector2(800, 30)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 13)
	add_child(note)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER):
		_start()


func _quality_row() -> void:
	var labels := ["HIGH", "MEDIUM", "LOW"]
	for i in 3:
		var b := Button.new()
		b.text = labels[i]
		b.toggle_mode = true
		b.button_pressed = i == _quality
		b.position = Vector2(720 + i * 160, 460)
		b.size = Vector2(140, 44)
		var idx := i
		b.pressed.connect(func() -> void:
			_quality = idx
			GraphicsProfile.set_named(["high", "medium", "low"][idx])
		)
		add_child(b)


func _start() -> void:
	AudioDirector.unlock()
	GraphicsProfile.set_named(["high", "medium", "low"][_quality])
	started.emit()
	queue_free()
