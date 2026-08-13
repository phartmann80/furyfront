class_name WeaponManager
extends Node3D

var ids: PackedStringArray = []
var idx: int = 0
var mag: int = 0
var reserve: int = 0
var reloading: bool = false
var _last_fire := -999.0
var _pattern_i := 0
var _view: MeshInstance3D
var _muzzle: Marker3D
var _hitscan: HitscanSystem
var _recoil_kick := Vector2.ZERO

func setup(weapon_ids: Array) -> void:
	ids.clear()
	for id in weapon_ids:
		ids.append(str(id))
	_hitscan = HitscanSystem.new()
	add_child(_hitscan)
	_view = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.12, 0.55)
	_view.mesh = box
	_view.position = Vector3(0.22, -0.18, -0.42)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.14)
	mat.metallic = 0.6
	mat.roughness = 0.35
	_view.material_override = mat
	add_child(_view)
	_muzzle = Marker3D.new()
	_muzzle.position = Vector3(0.22, -0.12, -0.72)
	add_child(_muzzle)
	_apply_index(0)


func current() -> Dictionary:
	if ids.is_empty():
		return {}
	return ContentCatalog.get_weapon(ids[idx])


func tick(_delta: float, firing: bool, ads: bool) -> void:
	_recoil_kick = _recoil_kick.move_toward(Vector2.ZERO, float(current().get("recoil", {}).get("recoverDegPerSec", 11)) * _delta * 0.02)
	if firing and not reloading:
		_try_fire(ads)


func _try_fire(ads: bool) -> void:
	var w := current()
	if w.is_empty():
		return
	if w.get("fireMode", "") == "melee":
		_melee(w)
		return
	if mag <= 0:
		AudioDirector.empty_click()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if not CombatMath.fire_legal(w, _last_fire, now):
		return
	_last_fire = now
	mag -= 1
	EventBus.ammo_changed.emit(mag, reserve)
	var bloom: float = float(w.get("recoil", {}).get("bloomAds" if ads else "bloomHip", 1.0))
	var spread := deg_to_rad(bloom)
	var dir := -get_viewport().get_camera_3d().global_transform.basis.z
	dir = _spread(dir, spread)
	var origin := get_viewport().get_camera_3d().global_position
	_hitscan.fire(w, origin, dir, _muzzle.global_position)
	_kick(w)
	AudioDirector.gunshot(str(w.get("audio", "")), origin)
	VfxBus.muzzle(_muzzle.global_position, dir)
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n.has_method("hear_event"):
			n.hear_event(origin)


func _melee(w: Dictionary) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_fire < 0.45:
		return
	_last_fire = now
	var cam := get_viewport().get_camera_3d()
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
	await get_tree().create_timer(float(w.get("reloadMs", 1800)) / 1000.0).timeout
	var need := cap - mag
	var take: int = mini(need, reserve)
	mag += take
	reserve -= take
	reloading = false
	EventBus.ammo_changed.emit(mag, reserve)


func cycle() -> void:
	if ids.is_empty():
		return
	_apply_index((idx + 1) % ids.size())


func refill() -> void:
	_apply_index(idx)


func set_ads_visual(t: float) -> void:
	if _view:
		_view.position = Vector3(lerpf(0.22, 0.0, t), lerpf(-0.18, -0.12, t), lerpf(-0.42, -0.38, t))


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
	EventBus.weapon_changed.emit(str(w.get("id", "")))
	EventBus.ammo_changed.emit(mag, reserve)


func _kick(w: Dictionary) -> void:
	var pattern: Array = w.get("recoil", {}).get("pattern", [])
	if pattern.is_empty():
		return
	var sample: Array = pattern[_pattern_i % pattern.size()]
	_pattern_i += 1
	_recoil_kick += Vector2(float(sample[0]), float(sample[1])) * 0.012
	var p := get_parent().get_parent()
	if p and p.get_parent() and p.get_parent() is PlayerController:
		var pc := p.get_parent() as PlayerController
		pc.yaw -= _recoil_kick.x
		pc.pitch += _recoil_kick.y


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
	await get_tree().create_timer(1.6 if kind == "frag" else 0.5).timeout
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
