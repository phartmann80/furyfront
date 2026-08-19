class_name WeaponManager
extends Node3D

const _V02 := preload("res://scripts/v02/v02_visuals.gd")

var ids: PackedStringArray = []
var idx: int = 0
var mag: int = 0
var reserve: int = 0
var reloading: bool = false
var recoil_yaw := 0.0
var recoil_pitch := 0.0
var _last_fire := -999.0
var _pattern_i := 0
var _rig: Node3D
var _muzzle: Node3D
var _shell: Node3D
var _mag: Node3D
var _mag_rest_y := 0.0
var _hitscan: HitscanSystem
var _ads_t := 0.0
var punch := Vector3.ZERO
var _sway_t := 0.0
var _hip := Vector3(0.22, -0.19, -0.40)
var _ads := Vector3(0.0, -0.135, -0.36)
var _sprint := Vector3(0.28, -0.28, -0.22)

func setup(weapon_ids: Array) -> void:
	ids.clear()
	for id in weapon_ids:
		ids.append(str(id))
	_hitscan = HitscanSystem.new()
	add_child(_hitscan)
	_build_kf16()
	_apply_index(0)


func _build_kf16() -> void:
	_rig = _V02.instance_scene(_V02.KF16, "weapon")
	if _rig == null:
		_rig = Node3D.new()
		_rig.name = "Kf16Rig"
		_fallback_boxes(_rig)
	_rig.name = "Kf16Rig"
	add_child(_rig)
	var arms := _V02.instance_scene(_V02.ARMS, "arms")
	if arms:
		arms.name = "FpsArmsClay"
		_rig.add_child(arms)
		arms.position = Vector3.ZERO
	_muzzle = _marker("MuzzleFlash", Vector3(0.0, 0.028, -0.58))
	_shell = _marker("ShellEject", Vector3(0.04, 0.04, -0.04))
	_mag = _V02.named(_rig, "Magazine") as Node3D
	if _mag:
		_mag_rest_y = _mag.position.y
	_rig.position = _hip


func _fallback_boxes(root: Node3D) -> void:
	_part(root, Vector3(0.052, 0.078, 0.28), Vector3(0, 0.012, 0.04), Color(0.11, 0.12, 0.13), 0.62)
	_part(root, Vector3(0.046, 0.038, 0.22), Vector3(0, 0.008, -0.18), Color(0.14, 0.15, 0.16), 0.5)
	_part(root, Vector3(0.022, 0.022, 0.30), Vector3(0, 0.028, -0.38), Color(0.2, 0.2, 0.21), 0.75)
	_part(root, Vector3(0.034, 0.034, 0.05), Vector3(0, 0.028, -0.54), Color(0.16, 0.16, 0.17), 0.7)
	_part(root, Vector3(0.038, 0.05, 0.14), Vector3(0, 0.0, 0.22), Color(0.09, 0.09, 0.1), 0.45)
	_part(root, Vector3(0.03, 0.1, 0.048), Vector3(0, -0.082, 0.02), Color(0.15, 0.13, 0.1), 0.2)
	_part(root, Vector3(0.018, 0.036, 0.07), Vector3(0, 0.062, -0.06), Color(0.07, 0.08, 0.08), 0.3)
	_part(root, Vector3(0.028, 0.018, 0.04), Vector3(0, 0.084, -0.05), Color(0.05, 0.06, 0.07), 0.15)
	var mag := _part(root, Vector3(0.028, 0.11, 0.05), Vector3(0, -0.09, -0.02), Color(0.1, 0.11, 0.1), 0.35)
	mag.name = "Magazine"


func _marker(named: String, fallback: Vector3) -> Node3D:
	var n := _V02.named(_rig, named) as Node3D
	if n:
		return n
	var m := Marker3D.new()
	m.name = named
	m.position = fallback
	_rig.add_child(m)
	return m


func _part(parent: Node3D, size: Vector3, pos: Vector3, color: Color, metallic: float = 0.45) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.38
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func current() -> Dictionary:
	if ids.is_empty():
		return {}
	return ContentCatalog.get_weapon(ids[idx])


func tick(delta: float, firing: bool, ads: bool, move_vel: Vector3 = Vector3.ZERO, sprinting: bool = false) -> void:
	var rec := deg_to_rad(float(current().get("recoil", {}).get("recoverDegPerSec", 11)))
	recoil_pitch = move_toward(recoil_pitch, 0.0, rec * delta)
	recoil_yaw = move_toward(recoil_yaw, 0.0, rec * 0.55 * delta)
	punch = punch.move_toward(Vector3.ZERO, delta * 8.5)
	_sway_t += delta
	if firing and not reloading:
		_try_fire(ads)
	_pose(delta, ads, move_vel, sprinting)


func _pose(_delta: float, ads: bool, move_vel: Vector3, sprinting: bool = false) -> void:
	if _rig == null:
		return
	var speed := Vector3(move_vel.x, 0.0, move_vel.z).length()
	var idle := 0.28 if speed < 0.4 else 1.0
	var sway := Vector3(sin(_sway_t * 1.15) * 0.006, cos(_sway_t * 0.9) * 0.004, 0.0) * idle
	if ads:
		sway *= 0.12
	var rest := _hip.lerp(_ads, _ads_t)
	if sprinting and _ads_t < 0.2:
		rest = rest.lerp(_sprint, 0.85)
	if reloading:
		rest += Vector3(0.05, -0.11, 0.07)
		if _mag:
			_mag.position.y = _mag_rest_y - 0.07
	elif _mag:
		_mag.position.y = _mag_rest_y
	_rig.position = rest + sway + punch
	_rig.rotation_degrees = Vector3(punch.z * 62.0, sway.x * 20.0 + punch.x * 18.0, sway.y * -18.0)


func _try_fire(ads: bool) -> void:
	var w := current()
	if w.is_empty():
		return
	if w.get("fireMode", "") == "melee":
		_melee(w)
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if mag <= 0:
		if now - _last_fire > 0.28:
			_last_fire = now
			AudioDirector.empty_click()
		return
	if not CombatMath.fire_legal(w, _last_fire, now):
		return
	_last_fire = now
	mag -= 1
	EventBus.ammo_changed.emit(mag, reserve)
	var bloom: float = float(w.get("recoil", {}).get("bloomAds" if ads else "bloomHip", 1.0))
	var spread := deg_to_rad(bloom)
	var cam := get_viewport().get_camera_3d()
	var dir := -cam.global_transform.basis.z
	dir = _spread(dir, spread)
	_hitscan.fire(w, cam.global_position, dir, _muzzle.global_position)
	_kick(w)
	punch += Vector3(0.004, 0.016, 0.05)
	AudioDirector.gunshot(str(w.get("audio", "")), cam.global_position)
	VfxBus.muzzle(_muzzle.global_position, dir)
	if GraphicsProfile.tier != GraphicsProfile.Tier.LOW:
		VfxBus.muzzle_smoke(_muzzle.global_position, dir)
		var shell_pos := _shell.global_position if _shell else _muzzle.global_position
		VfxBus.shell_eject(shell_pos, cam.global_transform.basis.x)
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n.has_method("hear_event"):
			n.hear_event(cam.global_position)


func _melee(w: Dictionary) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_fire < 0.45:
		return
	_last_fire = now
	var cam := get_viewport().get_camera_3d()
	punch += Vector3(0.0, -0.02, 0.04)
	_hitscan.fire(w, cam.global_position, -cam.global_transform.basis.z, cam.global_position)


func reload() -> void:
	var w := current()
	if reloading or w.get("fireMode", "") == "melee":
		return
	var cap := int(w.get("mag", 0))
	if mag >= cap or reserve <= 0:
		return
	reloading = true
	AudioDirector.reload()
	var ms := float(w.get("reloadMs", 1800))
	if mag <= 0:
		ms = float(w.get("reloadEmptyMs", ms))
	await get_tree().create_timer(ms / 1000.0, false).timeout
	if not is_instance_valid(self):
		return
	var need := cap - mag
	var take: int = mini(need, reserve)
	mag += take
	reserve -= take
	reloading = false
	_pattern_i = 0
	EventBus.ammo_changed.emit(mag, reserve)


func cycle() -> void:
	if ids.is_empty() or reloading:
		return
	punch += Vector3(0.05, -0.08, 0.1)
	_apply_index((idx + 1) % ids.size())


func refill() -> void:
	_apply_index(idx)


func set_ads_visual(t: float) -> void:
	_ads_t = t


func throw_grenade() -> void:
	EventBus.notify.emit("FRAG OUT")
	_spawn_thrown("frag")


func throw_tactical() -> void:
	EventBus.notify.emit("STIM / SMOKE")
	_spawn_thrown("smoke")


func _apply_index(i: int) -> void:
	idx = i
	var w := current()
	mag = int(w.get("mag", 0))
	reserve = int(w.get("reserves", 0))
	_pattern_i = 0
	reloading = false
	recoil_pitch = 0.0
	recoil_yaw = 0.0
	EventBus.weapon_changed.emit(str(w.get("id", "")))
	EventBus.ammo_changed.emit(mag, reserve)
	if _rig:
		_rig.visible = str(w.get("fireMode", "")) != "melee"


func _kick(w: Dictionary) -> void:
	var pattern: Array = w.get("recoil", {}).get("pattern", [])
	if pattern.is_empty():
		return
	var sample: Array = pattern[_pattern_i % pattern.size()]
	_pattern_i += 1
	var ads_mul := 0.62 if _ads_t > 0.5 else 1.0
	recoil_yaw -= deg_to_rad(float(sample[0])) * ads_mul
	recoil_pitch += deg_to_rad(float(sample[1])) * ads_mul


func _spread(dir: Vector3, rad: float) -> Vector3:
	if rad <= 0.0001:
		return dir.normalized()
	var rand := Vector2(randf_range(-rad, rad), randf_range(-rad, rad))
	var basis := Basis.looking_at(dir, Vector3.UP)
	return (dir + basis.x * rand.x + basis.y * rand.y).normalized()


func _spawn_thrown(kind: String) -> void:
	var body := RigidBody3D.new()
	var mesh := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.08
	mesh.mesh = sph
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.08
	col.shape = s
	body.add_child(col)
	var cam := get_viewport().get_camera_3d()
	body.global_position = cam.global_position + -cam.global_transform.basis.z * 0.8
	get_tree().current_scene.add_child(body)
	body.apply_impulse(-cam.global_transform.basis.z * 12.0 + Vector3.UP * 2.0)
	await get_tree().create_timer(1.6 if kind == "frag" else 0.5, false).timeout
	if is_instance_valid(body):
		if kind == "frag":
			_explode(body.global_position)
		else:
			VfxBus.smoke(body.global_position)
		body.queue_free()


func _explode(pos: Vector3) -> void:
	VfxBus.explosion(pos)
	AudioDirector.explosion(pos)
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n is Node3D:
			var sb := n as Node3D
			if sb.global_position.distance_to(pos) < 6.5 and sb.has_method("receive_hit"):
				var falloff: float = 1.0 - sb.global_position.distance_to(pos) / 6.5
				sb.receive_hit(90.0 * falloff, "chest", pos)
