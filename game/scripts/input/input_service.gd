extends Node

var touch_move: Vector2 = Vector2.ZERO
var touch_look: Vector2 = Vector2.ZERO
var fire_held: bool = false
var ads_held: bool = false
var sprint_held: bool = false
var crouch_held: bool = false

# Radians per mouse pixel at look_sensitivity 1.0. 0.12 was ~75× too hot for pointer-lock web mice.
const LOOK_BASE := 0.00165
const LOOK_MIN := 0.25
const LOOK_MAX := 2.5
const LOOK_STEP := 0.15
const SETTINGS_PATH := "user://ff_settings.cfg"

var look_sensitivity := 1.0
var _touch_look_sens := 0.004


func _ready() -> void:
	_load_settings()
	_bind()
	# Web requires a user click before pointer lock. Capture happens from Start Operation.


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
	_key("ui_accept", KEY_ENTER)
	_key("look_down", KEY_BRACKETLEFT)
	_key("look_up", KEY_BRACKETRIGHT)


func move_vector() -> Vector2:
	var k := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if touch_move.length_squared() > 0.0001:
		return touch_move.limit_length(1.0)
	return k


func look_delta() -> Vector2:
	return touch_look * _touch_look_sens * look_sensitivity


func is_fire() -> bool:
	return fire_held or Input.is_action_pressed("fire")


func is_ads() -> bool:
	return ads_held or Input.is_action_pressed("ads")


func is_sprint() -> bool:
	return sprint_held or Input.is_action_pressed("sprint")


func is_crouch() -> bool:
	return crouch_held or Input.is_action_pressed("crouch")


func consume_look() -> Vector2:
	var d := touch_look * LOOK_BASE * look_sensitivity
	touch_look = Vector2.ZERO
	return d


func nudge_look(dir: int) -> void:
	set_look_sensitivity(look_sensitivity + LOOK_STEP * float(dir))


func set_look_sensitivity(v: float) -> void:
	look_sensitivity = clampf(v, LOOK_MIN, LOOK_MAX)
	_save_settings()
	EventBus.notify.emit("Look sensitivity  %d%%" % int(round(look_sensitivity * 100.0)))


func capture_mouse() -> void:
	if OS.has_feature("mobile"):
		return
	if get_tree() != null and get_tree().paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if get_tree() != null and get_tree().paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		touch_look += event.relative
	if event.is_action_pressed("look_down"):
		nudge_look(-1)
	if event.is_action_pressed("look_up"):
		nudge_look(1)
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	look_sensitivity = clampf(float(cf.get_value("look", "sensitivity", 1.0)), LOOK_MIN, LOOK_MAX)


func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("look", "sensitivity", look_sensitivity)
	cf.save(SETTINGS_PATH)
