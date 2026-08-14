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
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_background(root)
	_ground_plate(root)
	_sky_titles(root)
	_ops_dock(root)


func _background(root: Control) -> void:
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = load(BG_PATH)
	if tex:
		bg.texture = tex
	root.add_child(bg)


func _ground_plate(root: Control) -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.38, 1.0])
	g.colors = PackedColorArray([
		Color(0.02, 0.02, 0.02, 0.0),
		Color(0.04, 0.03, 0.02, 0.42),
		Color(0.02, 0.015, 0.01, 0.72),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 16
	tex.height = 256
	var fade := TextureRect.new()
	fade.texture = tex
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.anchor_left = 0.0
	fade.anchor_right = 1.0
	fade.anchor_top = 0.66
	fade.anchor_bottom = 1.0
	root.add_child(fade)
	var rule := ColorRect.new()
	rule.color = Color(0.91, 0.64, 0.09, 0.38)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.anchor_left = 0.18
	rule.anchor_right = 0.82
	rule.anchor_top = 0.775
	rule.anchor_bottom = 0.775
	rule.offset_top = -1.0
	rule.offset_bottom = 1.0
	root.add_child(rule)


func _sky_titles(root: Control) -> void:
	_label(root, "FURY FRONT", 0.0, 0.045, 1.0, 0.155, 76, Color(0.91, 0.64, 0.09), 16)
	_label(root, "PC WEB  ·  OPERATION: BROKEN PERIMETER  ·  IRONFALL DEPOT", 0.08, 0.145, 0.92, 0.205, 18, Color(0.90, 0.91, 0.92), 7)


func _ops_dock(root: Control) -> void:
	var dock := VBoxContainer.new()
	dock.anchor_left = 0.22
	dock.anchor_right = 0.78
	dock.anchor_top = 0.78
	dock.anchor_bottom = 0.97
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 14)
	root.add_child(dock)
	var controls := Label.new()
	controls.text = "WASD move  ·  Mouse look  ·  LMB fire  ·  RMB ADS  ·  R reload  ·  Shift sprint  ·  C crouch  ·  Space jump  ·  E interact"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color(0.84, 0.86, 0.88))
	controls.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.88))
	controls.add_theme_constant_override("outline_size", 5)
	dock.add_child(controls)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	dock.add_child(row)
	var labels := ["HIGH", "MEDIUM", "LOW"]
	for i in 3:
		var b := Button.new()
		b.text = labels[i]
		b.toggle_mode = true
		b.button_pressed = i == _quality
		b.custom_minimum_size = Vector2(168, 48)
		var idx := i
		b.pressed.connect(func() -> void:
			_quality = idx
			for j in _quality_buttons.size():
				_quality_buttons[j].button_pressed = j == idx
				_apply_style(_quality_buttons[j], j == idx, false)
			GraphicsProfile.set_named(["high", "medium", "low"][idx])
		)
		_apply_style(b, i == _quality, false)
		row.add_child(b)
		_quality_buttons.append(b)
	var start := Button.new()
	start.text = "START OPERATION"
	start.custom_minimum_size = Vector2(420, 64)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_style(start, false, true)
	start.pressed.connect(_start)
	dock.add_child(start)
	start.grab_focus()
	var note := Label.new()
	note.text = "Click starts audio and mouse capture (browser requirement)."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.74, 0.76, 0.78))
	note.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	note.add_theme_constant_override("outline_size", 4)
	dock.add_child(note)


func _label(root: Control, text: String, left: float, top: float, right: float, bottom: float, font_size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.anchor_left = left
	l.anchor_top = top
	l.anchor_right = right
	l.anchor_bottom = bottom
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.86))
	l.add_theme_constant_override("outline_size", outline)
	root.add_child(l)
	return l


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER):
		_start()


func _apply_style(b: Button, selected: bool, primary: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.04, 0.03, 0.48 if primary else 0.34)
	box.border_color = Color(0.91, 0.64, 0.09, 0.92) if selected or primary else Color(0.82, 0.78, 0.7, 0.32)
	box.set_border_width_all(2 if primary or selected else 1)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	box.set_content_margin_all(10)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.06, 0.03, 0.55)
	hover.border_color = Color(0.91, 0.64, 0.09, 0.95)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", Color(0.91, 0.64, 0.09) if selected else Color(0.93, 0.94, 0.95))
	b.add_theme_color_override("font_hover_color", Color(0.95, 0.78, 0.28))
	b.add_theme_color_override("font_pressed_color", Color(0.91, 0.64, 0.09))
	b.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.72))
	b.add_theme_constant_override("outline_size", 4)


func _start() -> void:
	AudioDirector.unlock()
	GraphicsProfile.set_named(["high", "medium", "low"][_quality])
	started.emit()
	queue_free()
