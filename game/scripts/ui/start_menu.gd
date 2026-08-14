extends CanvasLayer

signal started

const BG_PATH := "res://assets/ui/start_background.png"

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
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.42)
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
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)
	var sub := Label.new()
	sub.text = "PC WEB  ·  OPERATION: BROKEN PERIMETER  ·  IRONFALL DEPOT"
	sub.position = Vector2(460, 300)
	sub.size = Vector2(1000, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	sub.add_theme_constant_override("shadow_offset_x", 1)
	sub.add_theme_constant_override("shadow_offset_y", 1)
	add_child(sub)
	var hint := Label.new()
	hint.text = "WASD move  ·  Mouse look  ·  LMB fire  ·  RMB ADS  ·  R reload  ·  Shift sprint  ·  C crouch  ·  Space jump  ·  E interact"
	hint.position = Vector2(160, 360)
	hint.size = Vector2(1600, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9))
	hint.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	add_child(hint)
	_quality_row()
	var start := Button.new()
	start.text = "START OPERATION"
	start.position = Vector2(760, 560)
	start.size = Vector2(400, 72)
	_apply_style(start, false, true)
	start.pressed.connect(_start)
	add_child(start)
	start.grab_focus()
	var note := Label.new()
	note.text = "Click starts audio and mouse capture (browser requirement)."
	note.position = Vector2(560, 650)
	note.size = Vector2(800, 30)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.82, 0.84, 0.86))
	note.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
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
	box.bg_color = Color(0.07, 0.08, 0.09, 0.78)
	box.border_color = Color(0.91, 0.64, 0.09) if selected else Color(0.9, 0.91, 0.93, 0.7)
	box.set_border_width_all(2 if primary or selected else 1)
	box.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", box)
	b.add_theme_stylebox_override("pressed", box)
	b.add_theme_stylebox_override("focus", box)
	b.add_theme_color_override("font_color", Color(0.91, 0.64, 0.09) if selected else Color(0.95, 0.96, 0.97))
	b.add_theme_color_override("font_hover_color", Color(0.91, 0.64, 0.09))
	b.add_theme_color_override("font_pressed_color", Color(0.91, 0.64, 0.09))


func _start() -> void:
	AudioDirector.unlock()
	GraphicsProfile.set_named(["high", "medium", "low"][_quality])
	started.emit()
	queue_free()
