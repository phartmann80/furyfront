class_name AllySoldier
extends CharacterBody3D

const _V02 := preload("res://scripts/v02/v02_visuals.gd")

const GRAVITY := 22.0
const FOLLOW_DIST := 4.8
const ENGAGE_RANGE := 32.0

var health: HealthComponent
var _fire_t := 0.0
var _slot := 0
var _weapon: Dictionary = {}

func setup(origin: Vector3, slot: int = 0) -> void:
	_slot = slot
	add_to_group("allies")
	# World only — do not use PLAYER layer so squadmates cannot body-block the operator.
	collision_layer = 0
	collision_mask = PhysLayers.WORLD
	global_position = origin
	health = HealthComponent.new()
	add_child(health)
	health.setup(100, 15, "fury_front")
	_weapon = ContentCatalog.get_weapon("ar_kf16")
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	var vis := _V02.character(true)
	if vis:
		vis.name = "Visual"
		add_child(vis)
	else:
		var mi := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.32
		cm.height = 1.8
		mi.mesh = cm
		mi.position = Vector3(0, 0.9, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.32, 0.22)
		mi.material_override = mat
		add_child(mi)


func _physics_process(delta: float) -> void:
	if health.dead or GameState.mission_over:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var enemy := _nearest_enemy()
	var dest := _follow_point(player)
	if enemy:
		var to_e := enemy.global_position - global_position
		to_e.y = 0.0
		if to_e.length() > 9.0:
			dest = enemy.global_position
		_try_shoot(delta, enemy)
	elif GameState.objective_pos != Vector3.ZERO and player:
		if player.global_position.distance_to(GameState.objective_pos) > 8.0:
			dest = GameState.objective_pos
	if player and enemy:
		var fwd := -player.transform.basis.z
		var to_me := global_position - player.global_position
		to_me.y = 0.0
		if to_me.length() > 0.08 and to_me.length() < 3.4 and fwd.dot(to_me.normalized()) > 0.55:
			dest = _follow_point(player)
	_move_to(dest)
	move_and_slide()
	if enemy:
		var look := enemy.global_position - global_position
		look.y = 0.0
		if look.length_squared() > 0.0001:
			look_at(global_position + look.normalized(), Vector3.UP)


func _follow_point(player: Node3D) -> Vector3:
	if player == null:
		return global_position
	var right := player.transform.basis.x
	var back := player.transform.basis.z
	var lateral := 2.4 if (_slot % 2) == 0 else -2.4
	return player.global_position + right * lateral + back * (1.6 + float(_slot) * 0.4)


func _move_to(dest: Vector3) -> void:
	var to := dest - global_position
	to.y = 0.0
	var d := to.length()
	if d < 1.6:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := to.normalized()
	var speed := 4.8 if d > 8.0 else 3.7
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if is_on_wall():
		var n := get_wall_normal()
		n.y = 0.0
		if n.length_squared() > 0.001:
			var slide := Vector3(n.z, 0.0, -n.x)
			velocity.x += slide.x * speed * 0.5
			velocity.z += slide.z * speed * 0.5
	if dir.length_squared() > 0.0001:
		look_at(global_position + dir, Vector3.UP)


func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := ENGAGE_RANGE
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if not (n is Shadowbreaker):
			continue
		var sb := n as Shadowbreaker
		if sb.health.dead:
			continue
		var d := global_position.distance_to(sb.global_position)
		if d < best_d and _los(sb):
			best_d = d
			best = sb
	return best


func _los(target: Node3D) -> bool:
	var origin := global_position + Vector3(0, 1.4, 0)
	var to := target.global_position + Vector3(0, 1.4, 0)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, to)
	q.collision_mask = PhysLayers.WORLD | PhysLayers.ENEMY
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.collider == target or (hit.collider is Node and (hit.collider as Node).get_parent() == target)


func _try_shoot(delta: float, enemy: Node3D) -> void:
	_fire_t -= delta
	if _fire_t > 0.0:
		return
	_fire_t = CombatMath.interval_s(_weapon) * 1.35
	var origin := global_position + Vector3(0, 1.4, 0)
	var dir := (enemy.global_position + Vector3(0, 1.35, 0) - origin).normalized()
	dir = (dir + Vector3(randf_range(-0.04, 0.04), randf_range(-0.02, 0.02), randf_range(-0.04, 0.04))).normalized()
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 70.0)
	q.collision_mask = PhysLayers.WORLD | PhysLayers.ENEMY | PhysLayers.HEAD
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	VfxBus.tracer(origin, hit.position)
	AudioDirector.gunshot("wpn_kf16", origin)
	var col: Object = hit.collider
	if col is Area3D:
		col = (col as Area3D).get_parent()
	if col and col.has_method("receive_hit"):
		var dmg := CombatMath.apply_hit(_weapon, origin.distance_to(hit.position), "chest", 0.0)
		col.receive_hit(float(dmg.applied) * 0.55, "chest", origin)
