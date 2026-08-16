class_name GatePresentation
extends Node3D
## Alarm pulse, courtyard smoke, and cheap Shadowbreach overlay. No extra shadows.

var _alarm := false
var _alarm_t := 0.0
var _lights: Array[OmniLight3D] = []
var _overlay: ColorRect


func _ready() -> void:
	add_to_group("gate_presentation")
	_install_lights()
	_install_smoke()
	_install_overlay()
	if not EventBus.alarm_started.is_connected(_on_alarm):
		EventBus.alarm_started.connect(_on_alarm)


func _process(delta: float) -> void:
	if _alarm:
		_alarm_t += delta
		var pulse := 0.55 + absf(sin(_alarm_t * 5.2)) * 1.35
		for l in _lights:
			if is_instance_valid(l):
				l.light_energy = pulse
		if _overlay:
			_overlay.color.a = 0.04 + absf(sin(_alarm_t * 2.4)) * 0.05
	elif _overlay and _overlay.color.a > 0.0:
		_overlay.color.a = move_toward(_overlay.color.a, 0.0, delta * 0.25)


func _on_alarm() -> void:
	_alarm = true
	if _overlay:
		_overlay.color = Color(0.55, 0.08, 0.06, 0.08)


func pulse_breach() -> void:
	if _overlay == null:
		return
	_overlay.color = Color(0.28, 0.12, 0.42, 0.22)
	await get_tree().create_timer(0.45, false).timeout
	if is_instance_valid(_overlay) and not _alarm:
		_overlay.color.a = 0.0


func _install_lights() -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW:
		return
	for x in [-4.8, 4.8]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.82, 0.55)
		l.light_energy = 1.15
		l.omni_range = 7.5
		l.shadow_enabled = false
		l.position = Vector3(x, 3.2, 33.5)
		add_child(l)
		_lights.append(l)
	var alarm := OmniLight3D.new()
	alarm.name = "AlarmLight"
	alarm.light_color = Color(0.95, 0.12, 0.08)
	alarm.light_energy = 0.0
	alarm.omni_range = 9.0
	alarm.shadow_enabled = false
	alarm.position = Vector3(0, 3.4, 33.8)
	add_child(alarm)
	_lights.append(alarm)


func _install_smoke() -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW:
		return
	var mi := MeshInstance3D.new()
	mi.name = "GateHaze"
	var sph := SphereMesh.new()
	sph.radius = 2.2
	sph.height = 3.4
	mi.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.42, 0.44, 0.45, 0.07)
	mi.material_override = mat
	mi.position = Vector3(0, 1.4, 31.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _install_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0.35, 0.08, 0.08, 0.0)
	layer.add_child(_overlay)
