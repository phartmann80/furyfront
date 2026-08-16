class_name WeaponManager
extends Node3D

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
var _muzzle: Marker3D
var _hitscan: HitscanSystem
var _ads_t := 0.0
var _punch := Vector3.ZERO
var _sway_t := 0.0
var _hip := Vector3(0.22, -0.19, -0.40)
var _ads := Vector3(0.0, -0.135, -0.36)

func setup(weapon_ids: Array) -> void:
	ids.clear()
	for id in weapon_ids:
		ids.append(str(id))
	_hitscan = HitscanSystem.new()
	add_child(_hitscan)
	_build_kf16()
	_apply_index(0)


func _build_kf16() -> void:
	_rig = Node3D.new()
	_rig.name = "Kf16Rig"
	add_child(_rig)
	_part(_rig, Vector3(0.055, 0.085, 0.30), Vector3(0, 0.01, 0.02), Color(0.12, 0.13, 0.14))
	_part(_rig, Vector3(0.028, 0.028, 0.34), Vector3(0, 0.03, -0.28), Color(0.18, 0.19, 0.20))
	_part(_rig, Vector3(0.04, 0.055, 0.16), Vector3(0, 0.0, 0.22), Color(0.10, 0.11, 0.12))
	_part(_rig, Vector3(0.032, 0.11, 0.055), Vector3(0, -0.085, 0.0), Color(0.16, 0.14, 0.11))
	_part(_rig, Vector3(0.03, 0.09, 0.04), Vector3(0, -0.09, 0.10), Color(0.11, 0.11, 0.12))
	_part(_rig, Vector3(0.02, 0.04, 0.08), Vector3(0, 0.06, -0.08), Color(0.08, 0.08, 0.09))
	_part(_rig, Vector3(0.05, 0.05, 0.26), Vector3(0.07, -0.07, 0.14), Color(0.42, 0.32, 0.22))
	_part(_rig, Vector3(0.045, 0.045, 0.20), Vector3(-0.05, -0.03, -0.06), Color(0.40, 0.30, 0.20))
	_muzzle = Marker3D.new()
	_muzzle.position = Vector3(0.0, 0.03, -0.48)
	_rig.add_child(_muzzle)
	_rig.position = _hip


func _part(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.45
	mat.roughness = 0.4
	mi.material_override = mat
	parent.add_child(mi)


func current() -> Dictionary:
	if ids.is_empty():
		return {}
	return ContentCatalog.get_weapon(ids[idx])


func tick(delta: float, firing: bool, ads: bool, move_vel: Vector3 = Vector3.ZERO) -> void:
	var rec := deg_to_rad(float(current().get("recoil", {}).get("recoverDegPerSec", 11)))
	recoil_pitch = move_toward(recoil_pitch, 0.0, rec * delta)
	recoil_yaw = move_toward(recoil_yaw, 0.0, rec * 0.55 * delta)
	_punch = _punch.move_toward(Vector3.ZERO, delta * 8.5)
	_sway_t += delta
	if firing and not reloading:
		_try_fire(ads)
	_pose(delta, ads, move_vel)


func _pose(_delta: float, ads: bool, move_vel: Vector3) -> void:
	if _rig == null:
		return
	var speed := Vector3(move_vel.x, 0.0, move_vel.z).length()
	var idle := 0.35 if speed < 0.4 else 1.0
	var sway := Vector3(sin(_sway_t * 1.15) * 0.006, cos(_sway_t * 0.9) * 0.004, 0.0) * idle
	if ads:
		sway *= 0.12
	var rest := _hip.lerp(_ads, _ads_t)
	if reloading:
		rest += Vector3(0.05, -0.11, 0.07)
	_rig.position = rest + sway + _punch
	_rig.rotation_degrees = Vector3(_punch.z * 52.0, sway.x * 20.0, sway.y * -18.0)


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
	_punch += Vector3(0.0, 0.012, 0.042)
	AudioDirector.gunshot(str(w.get("audio", "")), cam.global_position)
	VfxBus.muzzle(_muzzle.global_position, dir)
	if GraphicsProfile.tier != GraphicsProfile.Tier.LOW:
		VfxBus.muzzle_smoke(_muzzle.global_position, dir)
		VfxBus.shell_eject(_muzzle.global_position, cam.global_transform.basis.x)
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n.has_method("hear_event"):
			n.hear_event(cam.global_position)


func _melee(w: Dictionary) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_fire < 0.45:
		return
	_last_fire = now
	var cam := get_viewport().get_camera_3d()
	_punch += Vector3(0.0, -0.02, 0.04)
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
