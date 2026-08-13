class_name ResultsScreen
extends CanvasLayer

func show_results(success: bool) -> void:
	layer = 50
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var t := Label.new()
	t.text = "MISSION SUCCESS" if success else "MISSION FAILED"
	t.position = Vector2(560, 360)
	t.size = Vector2(800, 70)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 36)
	t.add_theme_color_override("font_color", Color(0.91, 0.64, 0.09) if success else Color(0.85, 0.25, 0.2))
	add_child(t)
	var d := Label.new()
	d.text = "Operation: Broken Perimeter  ·  Ironfall Depot\nClick the game to recapture the mouse, or press Esc."
	d.position = Vector2(560, 440)
	d.size = Vector2(800, 80)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(d)
	var b := Button.new()
	b.text = "RETURN TO START"
	b.position = Vector2(760, 560)
	b.size = Vector2(400, 56)
	b.pressed.connect(func() -> void:
		get_tree().reload_current_scene()
	)
	add_child(b)
