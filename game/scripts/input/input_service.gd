extends Node

var touch_move: Vector2 = Vector2.ZERO
var touch_look: Vector2 = Vector2.ZERO
var fire_held: bool = false
var ads_held: bool = false
var sprint_held: bool = false
var crouch_held: bool = false

var _look_sens := 0.12
var _touch_look_sens := 0.18


func _ready() -> void:
	_bind()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _bind() -> void:
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("move_forward", KEY_W)
	_key("move_back", KEY_S)
	_mouse("fire", MOUSE_BUTTON_LEFT)
	_mouse("ads", MOUSE_BUTTON_RIGHT)
	_key("reload", KEY_R)
	_key("sprint", KEY_SHIFT)
	_key("crouch", KEY_C)
	_key("jump", KEY_SPACE)
	_key("weapon_next", KEY_Q)
	_key("grenade", KEY_G)
	_key("tactical", KEY_T)
	_key("interact", KEY_E)
	_key("debug_reset", KEY_F9)
	_key("ui_cancel", KEY_ESCAPE)


func move_vector() -> Vector2:
	var k := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if touch_move.length_squared() > 0.0001:
		return touch_move.limit_length(1.0)
	return k


func look_delta() -> Vector2:
	return touch_look * _touch_look_sens


func is_fire() -> bool:
	return fire_held or Input.is_action_pressed("fire")


func is_ads() -> bool:
	return ads_held or Input.is_action_pressed("ads")


func is_sprint() -> bool:
	return sprint_held or Input.is_action_pressed("sprint")


func is_crouch() -> bool:
	return crouch_held or Input.is_action_pressed("crouch")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		touch_look += event.relative
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func consume_look() -> Vector2:
	var d := touch_look * _look_sens
	touch_look = Vector2.ZERO
	return d


func _key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)


func _mouse(action: String, btn: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)
