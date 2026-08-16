class_name FpsArms
extends Node3D
## First-person arm/hand placeholders. Pose bounds only — not a full animation library.

var _left: Node3D
var _right: Node3D
var _sway_t := 0.0
var _switch_t := 0.0


func _ready() -> void:
	name = "FpsArms"
	_left = _arm(-1.0)
	_right = _arm(1.0)
	add_child(_left)
	add_child(_right)


func notify_switch() -> void:
	_switch_t = 1.0


func pose(delta: float, ads: float, sprinting: bool, reloading: bool, speed: float, punch: Vector3) -> void:
	_sway_t += delta
	_switch_t = move_toward(_switch_t, 0.0, delta * 3.2)
	var walk := 1.0 if speed > 1.2 else 0.28
	var sway := Vector3(sin(_sway_t * 6.2) * 0.012, cos(_sway_t * 3.1) * 0.008, 0.0) * walk
	if ads > 0.5:
		sway *= 0.12
	if sprinting:
		_left.position = Vector3(-0.28, -0.34, -0.18) + sway * 1.4
		_left.rotation_degrees = Vector3(18.0, 12.0, -8.0)
		_right.position = Vector3(0.22, -0.32, -0.22) + sway * 1.4 + punch
		_right.rotation_degrees = Vector3(22.0, -18.0, 10.0)
		return
	var ads_l := Vector3(-0.12, -0.2, -0.34).lerp(Vector3(-0.05, -0.16, -0.28), ads)
	var ads_r := Vector3(0.18, -0.22, -0.30).lerp(Vector3(0.06, -0.14, -0.26), ads)
	if reloading:
		ads_r += Vector3(0.04, -0.1, 0.06)
		ads_l += Vector3(0.02, -0.06, 0.04)
	if _switch_t > 0.01:
		ads_r += Vector3(0.08, -0.14, 0.1) * _switch_t
		ads_l += Vector3(-0.04, -0.08, 0.06) * _switch_t
	_left.position = ads_l + sway
	_right.position = ads_r + sway + punch * 0.65
	_left.rotation_degrees = Vector3(8.0 - ads * 6.0, 6.0, -4.0)
	_right.rotation_degrees = Vector3(6.0 - ads * 4.0, -8.0, 6.0)


func _arm(side: float) -> Node3D:
	var root := Node3D.new()
	root.name = "ArmL" if side < 0.0 else "ArmR"
	var sleeve := _box(Vector3(0.055, 0.055, 0.22), Vector3(0, -0.02, 0.12), Color(0.14, 0.16, 0.15))
	var glove := _box(Vector3(0.07, 0.065, 0.09), Vector3(0, -0.01, -0.02), Color(0.08, 0.08, 0.07))
	var knuckle := _box(Vector3(0.075, 0.03, 0.04), Vector3(0, 0.02, -0.05), Color(0.1, 0.1, 0.09))
	root.add_child(sleeve)
	root.add_child(glove)
	root.add_child(knuckle)
	root.position = Vector3(0.18 * side, -0.22, -0.30)
	return root


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mi.material_override = mat
	return mi
