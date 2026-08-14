extends CanvasLayer

signal started

const BG_PATH := "res://assets/ui/start_background.jpg"

var _quality: int = 1 # High=0 Medium=1 Low=2
var _quality_buttons: Array[Button] = []


func _ready() -> void:
	layer = 100
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()


func _build() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(BG_PATH)
	if tex:
		bg.texture = tex
	add_child(bg)
	var catcher := ColorRect.new()
	catcher.color = Color(0, 0, 0, 0)
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(catcher)
	_label("FURY FRONT", Vector2(360, 168), Vector2(1200, 96), 72, Color(0.93, 0.62, 0.16), 14)
	_label("PC WEB  ·  OPERATION: BROKEN PERIMETER  ·  IRONFALL DEPOT", Vector2(260, 268), Vector2(1400, 40), 18, Color(0.90, 0.88, 0.82), 7)
	_label("WASD move  ·  Mouse look  ·  LMB fire  ·  RMB ADS  ·  R reload  ·  Shift sprint  ·  C crouch  ·  Space jump  ·  E interact", Vector2(80, 318), Vector2(1760, 36), 15, Color(0.82, 0.80, 0.74), 6)
	_quality_row()
	var start := Button.new()
	start.text = "START OPERATION"
	start.position = Vector2(710, 548)
	start.size = Vector2(500, 78)
	_apply_style(start, false, true)
	start.pressed.connect(_start)
	add_child(start)
	start.grab_focus()
	_label("Click starts audio and mouse capture (browser requirement).", Vector2(360, 640), Vector2(1200, 32), 14, Color(0.72, 0.70, 0.64), 5)


func _label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.92))
	l.add_theme_constant_override("outline_size", outline)
	add_child(l)
	return l


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
		b.position = Vector2(705 + i * 170, 430)
		b.size = Vector2(156, 50)
		var idx := i
		b.pressed.connect(func() -> void:
			_quality = idx
			for j in _quality_buttons.size():
				_quality_buttons[j].button_pressed = j == idx
				_apply_style(_quality_buttons[j], j == idx, false)
			GraphicsProfile.set_named(["high", "medium", "low"][idx])
		)
		_apply_style(b, i == _quality, false)
		add_child(b)
		_quality_buttons.append(b)


func _apply_style(b: Button, selected: bool, primary: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.10, 0.06, 0.03, 0.42 if primary else 0.34)
	box.border_color = Color(0.93, 0.62, 0.16, 0.95) if selected or primary else Color(0.78, 0.58, 0.32, 0.45)
	box.set_border_width_all(2 if primary or selected else 1)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	box.set_content_margin_all(8)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.09, 0.04, 0.55)
	hover.border_color = Color(0.95, 0.70, 0.22, 0.98)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", Color(0.93, 0.62, 0.16) if selected else Color(0.94, 0.90, 0.82))
	b.add_theme_color_override("font_hover_color", Color(0.96, 0.78, 0.32))
	b.add_theme_color_override("font_pressed_color", Color(0.93, 0.62, 0.16))
	b.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.01, 0.85))
	b.add_theme_constant_override("outline_size", 4)


func _start() -> void:
	AudioDirector.unlock()
	GraphicsProfile.set_named(["high", "medium", "low"][_quality])
	started.emit()
	queue_free()
