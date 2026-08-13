class_name Shadowbreaker
extends CharacterBody3D

enum State { IDLE, PATROL, SUSPICIOUS, INVESTIGATE, ENGAGE, SEARCH, RETREAT }

const GRAVITY := 22.0

var archetype_id: String = "sb_phantom"
var skill_id: String = "trained"
var def: Dictionary = {}
var skill: Dictionary = {}
var state: State = State.PATROL
var last_known := Vector3.ZERO
var has_lkp := false
var patrol_points: Array[Vector3] = []
var patrol_i := 0
var _fire_t := 0.0
var _reposition_t := 0.0
var _state_t := 0.0
var _agent: NavigationAgent3D
var health: HealthComponent
var _weapon: Dictionary = {}

func setup(id: String, skill_name: String, points: Array[Vector3]) -> void:
	archetype_id = id
	skill_id = skill_name
	def = ContentCatalog.enemies.get(id, {})
	skill = ContentCatalog.skill_profiles.get(skill_name, {})
	_weapon = ContentCatalog.get_weapon(str(def.get("weaponId", "smg_wasp")))
	patrol_points = points
	add_to_group("shadowbreakers")
	collision_layer = PhysLayers.ENEMY
	collision_mask = PhysLayers.WORLD | PhysLayers.PLAYER | PhysLayers.COVER
	health = HealthComponent.new()
	add_child(health)
	health.setup(int(def.get("health", 100)), int(def.get("armor", 0)), "shadowbreakers")
	health.died.connect(_die)
	_agent = NavigationAgent3D.new()
	_agent.max_speed = 4.6 * float(def.get("move", 1.0))
	_agent.avoidance_enabled = true
	add_child(_agent)
	_make_body()
	if not patrol_points.is_empty():
		_agent.target_position = patrol_points[0]


func _make_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.38
	cm.height = 1.8
	mi.mesh = cm
	mi.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	match archetype_id:
		"sb_hacker":
			mat.albedo_color = Color(0.15, 0.35, 0.4)
		"sb_enforcer":
			mat.albedo_color = Color(0.18, 0.16, 0.2)
			mi.scale = Vector3(1.15, 1.05, 1.15)
		"sb_commander":
			mat.albedo_color = Color(0.45, 0.12, 0.12)
		_:
			mat.albedo_color = Color(0.12, 0.14, 0.18)
	mi.material_override = mat
	add_child(mi)
	_hitbox("hit_head", Vector3(0, 1.62, 0), 0.16, 8)
	_hitbox("hit_limb", Vector3(0.22, 0.4, 0), 0.14, 16)


func _hitbox(group: String, pos: Vector3, r: float, layer: int) -> void:
	var a := Area3D.new()
	a.collision_layer = layer
	a.collision_mask = 0
	a.monitorable = true
	a.monitoring = false
	a.add_to_group(group)
	var c := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = r
	c.shape = s
	a.add_child(c)
	add_child(a)
	a.position = pos


func _physics_process(delta: float) -> void:
	if health.dead:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_state_t += delta
	var player := _player()
	var sees := player != null and _can_see(player)
	if sees:
		last_known = player.global_position
		has_lkp = true
		if state < State.ENGAGE:
			_set_state(State.ENGAGE)
	match state:
		State.PATROL:
			_patrol()
		State.SUSPICIOUS, State.INVESTIGATE, State.SEARCH:
			_go_lkp()
			if _state_t > 6.0 and not sees:
				_set_state(State.PATROL)
		State.ENGAGE:
			_engage(delta, player, sees)
		State.RETREAT:
			_retreat()
	_steer(delta)
	move_and_slide()


func _patrol() -> void:
	if patrol_points.is_empty():
		return
	if global_position.distance_to(patrol_points[patrol_i]) < 1.4:
		patrol_i = (patrol_i + 1) % patrol_points.size()
	_agent.target_position = patrol_points[patrol_i]


func _go_lkp() -> void:
	if has_lkp:
		_agent.target_position = last_known


func _engage(delta: float, player: Node3D, sees: bool) -> void:
	if player == null:
		_set_state(State.SEARCH)
		return
	if not sees:
		_set_state(State.SEARCH)
		return
	var dist := global_position.distance_to(player.global_position)
	var flank := float(skill.get("flank", 0.3))
	_reposition_t -= delta
	if _reposition_t <= 0.0:
		var side := transform.basis.x * (4.0 if randf() < flank else 0.0) * (1.0 if randf() > 0.5 else -1.0)
		var back := -transform.basis.z * (2.0 if dist < 8.0 else -1.5)
		_agent.target_position = player.global_position + side + back
		_reposition_t = 1.2 + randf() * 0.8
	if def.get("hacksObjectives", false) and dist > 14.0:
		# Push objective instead of chasing forever.
		var servers := get_tree().get_nodes_in_group("objective_server")
		if servers.size() > 0 and servers[0] is Node3D:
			_agent.target_position = (servers[0] as Node3D).global_position
	_fire_t -= delta
	if _fire_t <= 0.0:
		_fire_t = float(skill.get("reactionS", 0.35)) + CombatMath.interval_s(_weapon)
		if randf() <= float(skill.get("accuracy", 0.5)):
			_shoot(player)
		if randf() < float(skill.get("grenadeChance", 0.1)) and dist < 18.0:
			EventBus.notify.emit("Shadowbreaker grenade!")


func _shoot(player: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.4, 0)
	var dir := (player.global_position + Vector3(0, 1.4, 0) - origin).normalized()
	var miss := (1.0 - float(skill.get("accuracy", 0.5))) * 0.08
	dir = (dir + Vector3(randf_range(-miss, miss), randf_range(-miss * 0.4, miss * 0.4), randf_range(-miss, miss))).normalized()
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 80.0)
	q.collision_mask = PhysLayers.WORLD | PhysLayers.PLAYER
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	VfxBus.tracer(origin, hit.position)
	AudioDirector.gunshot(str(_weapon.get("audio", "")), origin)
	var col: Object = hit.collider
	if col is PlayerController:
		var dmg := CombatMath.apply_hit(_weapon, origin.distance_to(hit.position), "chest", 0.0)
		(col as PlayerController).take_hit(float(dmg.applied), origin)


func _retreat() -> void:
	if not patrol_points.is_empty():
		_agent.target_position = patrol_points[0]


func _steer(_delta: float) -> void:
	var dest: Vector3 = _agent.target_position
	if not _agent.is_navigation_finished():
		var next: Vector3 = _agent.get_next_path_position()
		if next.distance_to(global_position) > 0.15:
			dest = next
	var dir := dest - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		dir = dir.normalized()
		var speed: float = _agent.max_speed
		if state == State.ENGAGE:
			speed *= 1.05
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if dir.length_squared() > 0.0001:
			look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _can_see(player: Node3D) -> bool:
	if _in_smoke():
		return false
	var origin := global_position + Vector3(0, 1.5, 0)
	var target := player.global_position + Vector3(0, 1.4, 0)
	var to := target - origin
	var vis := float(def.get("visionM", 28))
	if to.length() > vis:
		return false
	var fwd := -transform.basis.z
	if fwd.normalized().dot(to.normalized()) < cos(deg_to_rad(float(def.get("fovDeg", 70)) * 0.5)):
		return false
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, target)
	q.collision_mask = PhysLayers.WORLD | PhysLayers.PLAYER
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.collider == player


func hear_event(pos: Vector3) -> void:
	if health.dead:
		return
	var hear := float(def.get("hearM", 16))
	if global_position.distance_to(pos) > hear:
		return
	last_known = pos
	has_lkp = true
	if state == State.PATROL or state == State.IDLE:
		_set_state(State.SUSPICIOUS)


func receive_hit(amount: float, hitbox: String, from: Vector3) -> Dictionary:
	last_known = from
	has_lkp = true
	_set_state(State.ENGAGE)
	var out := health.apply_damage(amount)
	out["id"] = archetype_id
	out["hitbox"] = hitbox
	return out


func _set_state(s: State) -> void:
	state = s
	_state_t = 0.0


func _in_smoke() -> bool:
	for n in get_tree().get_nodes_in_group("smoke_volume"):
		if n is Node3D and (n as Node3D).global_position.distance_to(global_position) < 3.2:
			return true
	return false


func _player() -> Node3D:
	var arr := get_tree().get_nodes_in_group("player")
	if arr.is_empty():
		return null
	return arr[0] as Node3D


func _die() -> void:
	collision_layer = 0
	await get_tree().create_timer(2.5).timeout
	queue_free()
