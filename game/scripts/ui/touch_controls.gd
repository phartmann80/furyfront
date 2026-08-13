class_name TouchControls
extends CanvasLayer

func _ready() -> void:
	layer = 20
	if not OS.has_feature("mobile") and DisplayServer.is_touchscreen_available() == false:
		# Keep visible in editor if you enable emulate_touch; otherwise hide on pure desktop.
		if not OS.has_feature("editor"):
			visible = false
	# Always show on mobile; also show in editor for layout testing via F1 later.
	if OS.has_feature("mobile"):
		visible = true
	_stick(Vector2(180, 820), true)
	_look_zone()
	_btn("FIRE", Vector2(1680, 780), Vector2(180, 140), func(d: bool) -> void: InputService.fire_held = d)
	_btn("ADS", Vector2(1480, 800), Vector2(140, 100), func(d: bool) -> void: InputService.ads_held = d)
	_tap("RELOAD", Vector2(1680, 680), func() -> void: Input.action_press("reload"); Input.action_release("reload"))
	_btn("SPRINT", Vector2(120, 680), Vector2(140, 80), func(d: bool) -> void: InputService.sprint_held = d)
	_btn("CROUCH", Vector2(280, 680), Vector2(140, 80), func(d: bool) -> void: InputService.crouch_held = d)
	_tap("JUMP", Vector2(1480, 680), func() -> void: Input.action_press("jump"); await get_tree().process_frame; Input.action_release("jump"))
	_tap("FRAG", Vector2(1320, 720), func() -> void: Input.action_press("grenade"); Input.action_release("grenade"))
	_tap("TAC", Vector2(1320, 820), func() -> void: Input.action_press("tactical"); Input.action_release("tactical"))
	_tap("WPN", Vector2(1160, 820), func() -> void: Input.action_press("weapon_next"); Input.action_release("weapon_next"))
	_btn("USE", Vector2(1160, 720), Vector2(140, 80), func(d: bool) -> void:
		if d:
			Input.action_press("interact")
		else:
			Input.action_release("interact")
	)


func _stick(pos: Vector2, _move: bool) -> void:
	var b := TouchScreenButton.new()
	var img := _circle(120, Color(1, 1, 1, 0.18))
	b.texture_normal = img
	b.position = pos - Vector2(60, 60)
	b.shape = CircleShape2D.new()
	(b.shape as CircleShape2D).radius = 70
	add_child(b)
	# Analog stick via _input on a Control
	var pad := Control.new()
	pad.position = pos - Vector2(90, 90)
	pad.size = Vector2(180, 180)
	pad.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventScreenTouch or ev is InputEventScreenDrag:
			var local: Vector2 = pad.get_local_mouse_position() - Vector2(90, 90)
			InputService.touch_move = (local / 90.0).limit_length(1.0)
			if ev is InputEventScreenTouch and not ev.pressed:
				InputService.touch_move = Vector2.ZERO
	)
	add_child(pad)


func _look_zone() -> void:
	var z := Control.new()
	z.position = Vector2(960, 0)
	z.size = Vector2(960, 1080)
	z.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventScreenDrag:
			InputService.touch_look += ev.relative
	)
	add_child(z)


func _btn(text: String, pos: Vector2, size: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.button_down.connect(func() -> void: cb.call(true))
	b.button_up.connect(func() -> void: cb.call(false))
	add_child(b)


func _tap(text: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(140, 80)
	b.pressed.connect(cb)
	add_child(b)


func _circle(r: int, color: Color) -> ImageTexture:
	var img := Image.create(r, r, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in r:
		for y in r:
			if Vector2(x - r / 2.0, y - r / 2.0).length() < r / 2.0 - 2:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
