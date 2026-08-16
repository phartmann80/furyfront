class_name Shadowbreaker
extends CharacterBody3D

enum State { IDLE, PATROL, SUSPICIOUS, INVESTIGATE, ENGAGE, SEARCH, COVER, FLANK, RETREAT }

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
var _stuck_t := 0.0
var _repath_t := 0.0
var _repath_interval := 0.32
var _queued_nav := Vector3.ZERO
var _has_queued_nav := false
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
	# RVO avoidance can stall unthreaded web exports; keep path follow only in browser.
	_agent.avoidance_enabled = not OS.has_feature("web")
	add_child(_agent)
	_make_body()
	# Stagger repaths so a wave does not rebuild nav in the same physics frame.
	_repath_interval = 0.28 + randf() * 0.12
	if not patrol_points.is_empty():
		_set_nav_target(patrol_points[0], true)


func _make_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	var radius := 0.32 if archetype_id == "sb_phantom" else 0.38
	var height := 1.72 if archetype_id == "sb_phantom" else 1.8
	cap.radius = radius
	cap.height = height
	col.shape = cap
	col.position = Vector3(0, height * 0.5, 0)
	add_child(col)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	mi.mesh = cm
	mi.position = Vector3(0, height * 0.5, 0)
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
			mat.albedo_color = Color(0.1, 0.12, 0.16)
			mat.metallic = 0.35
			mat.roughness = 0.42
	mi.material_override = mat
	add_child(mi)
	if archetype_id == "sb_phantom":
		_phantom_kit(height)
	_hitbox("hit_head", Vector3(0, height * 0.9, 0), 0.16 if archetype_id != "sb_phantom" else 0.14, 8)
	_hitbox("hit_limb", Vector3(0.22, 0.4, 0), 0.14, 16)


func _phantom_kit(height: float) -> void:
	var visor := MeshInstance3D.new()
	var vb := BoxMesh.new()
	vb.size = Vector3(0.28, 0.08, 0.18)
	visor.mesh = vb
	visor.position = Vector3(0, height * 0.82, -0.22)
	var vm := StandardMaterial3D.new()
	vm.albedo_color = Color(0.04, 0.08, 0.1)
	vm.emission_enabled = true
	vm.emission = Color(0.12, 0.55, 0.62)
	vm.emission_energy_multiplier = 1.6
	visor.material_override = vm
	add_child(visor)
	var pack := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.22, 0.28, 0.1)
	pack.mesh = pb
	pack.position = Vector3(0, height * 0.55, 0.28)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.08, 0.1, 0.12)
	pm.metallic = 0.45
	pack.material_override = pm
	add_child(pack)


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
	if health.dead or GameState.mission_over:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_state_t += delta
	_flush_nav(delta)
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
			if global_position.distance_to(last_known) < 1.6 and not sees:
				_set_state(State.SEARCH if has_lkp else State.PATROL)
			if _state_t > 7.0 and not sees:
				_set_state(State.PATROL)
		State.COVER, State.FLANK, State.ENGAGE:
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
		_set_nav_target(patrol_points[patrol_i], true)
	else:
		_set_nav_target(patrol_points[patrol_i])


func _go_lkp() -> void:
	if has_lkp:
		_set_nav_target(last_known)


func _engage(delta: float, player: Node3D, sees: bool) -> void:
	if player == null:
		_set_state(State.SEARCH)
		return
	if not sees:
		_set_state(State.SEARCH)
		return
	var dist := global_position.distance_to(player.global_position)
	_reposition_t -= delta
	if _reposition_t <= 0.0:
		_reposition_t = 1.4 + randf() * 1.1
		var flank_bias := float(skill.get("flank", 0.3))
		if archetype_id == "sb_phantom":
			flank_bias = maxf(flank_bias, 0.72)
		elif archetype_id == "sb_enforcer":
			flank_bias = minf(flank_bias, 0.28)
		if def.get("hacksObjectives", false) and dist > 11.0:
			var servers := get_tree().get_nodes_in_group("objective_server")
			if servers.size() > 0 and servers[0] is Node3D:
				_set_nav_target((servers[0] as Node3D).global_position, true)
				_set_state(State.ENGAGE)
		elif randf() < flank_bias:
			_set_nav_target(_cover_or_flank(player, true), true)
			_set_state(State.FLANK)
		else:
			_set_nav_target(_cover_or_flank(player, false), true)
			_set_state(State.COVER)
	if archetype_id == "sb_enforcer" and dist > 10.0:
		_set_nav_target(player.global_position + player.transform.basis.x * 2.5)
	if archetype_id == "sb_phantom":
		_guard_hacker(player)
	_fire_t -= delta
	if _fire_t <= 0.0:
		_fire_t = float(skill.get("reactionS", 0.35)) + CombatMath.interval_s(_weapon)
		var acc := float(skill.get("accuracy", 0.5))
		if state == State.COVER:
			acc *= 1.12
		if randf() <= acc:
			_shoot(player)


func _cover_or_flank(player: Node3D, flank: bool) -> Vector3:
	var best := player.global_position + -player.transform.basis.z * (-4.0)
	var best_s := -1.0e9
	for n in get_tree().get_nodes_in_group("cover"):
		if not (n is Node3D):
			continue
		var c: Vector3 = (n as Node3D).global_position
		var away := c - player.global_position
		away.y = 0.0
		if away.length() < 0.4:
			continue
		away = away.normalized()
		var hide := c + away * 1.85
		hide.y = global_position.y
		var travel := global_position.distance_to(hide)
		if travel > 22.0:
			continue
		var right := player.transform.basis.x
		var lateral := absf(right.dot((hide - player.global_position).normalized()))
		var score := 10.0 - travel * 0.2
		if flank:
			score += lateral * 12.0
		else:
			score += 5.0 if travel < 10.0 else 0.0
		if score > best_s:
			best_s = score
			best = hide
	return best


func _guard_hacker(player: Node3D) -> void:
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n is Shadowbreaker and (n as Shadowbreaker).archetype_id == "sb_hacker":
			var h := n as Node3D
			var mid := h.global_position.lerp(player.global_position, 0.35)
			if global_position.distance_to(h.global_position) > 8.0:
				_set_nav_target(mid)
			return


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
		_set_nav_target(patrol_points[0], true)


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
		elif state == State.FLANK:
			speed *= 1.18
		elif state == State.COVER:
			speed *= 0.62
		elif state == State.INVESTIGATE:
			speed *= 0.9
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var look_dir := dir
		var player := _player()
		if player and (state == State.ENGAGE or state == State.COVER) and _can_see(player):
			look_dir = player.global_position - global_position
			look_dir.y = 0.0
		if is_on_wall():
			var n := get_wall_normal()
			n.y = 0.0
			if n.length_squared() > 0.001:
				n = n.normalized()
				var slide := Vector3(n.z, 0.0, -n.x)
				velocity.x += slide.x * speed * 0.55
				velocity.z += slide.z * speed * 0.55
		var horiz := Vector3(velocity.x, 0.0, velocity.z)
		if horiz.length() < 0.25 and dir.length() > 1.6:
			_stuck_t += _delta
			if _stuck_t > 0.7:
				_set_nav_target(global_position + Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0)), true)
				_stuck_t = 0.0
		else:
			_stuck_t = 0.0
		if look_dir.length_squared() > 0.0001:
			look_at(global_position + look_dir.normalized(), Vector3.UP)
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
		_set_state(State.INVESTIGATE)


func receive_hit(amount: float, hitbox: String, from: Vector3) -> Dictionary:
	if GameState.mission_over or health.dead:
		return { "applied": 0, "killed": false, "to_armor": 0, "to_health": 0, "id": archetype_id, "hitbox": hitbox }
	last_known = from
	has_lkp = true
	_set_state(State.ENGAGE)
	var out := health.apply_damage(amount)
	out["id"] = archetype_id
	out["hitbox"] = hitbox
	return out


func _set_nav_target(pos: Vector3, force: bool = false) -> void:
	if _agent == null:
		return
	if force:
		_agent.target_position = pos
		_repath_t = _repath_interval
		_has_queued_nav = false
		return
	if _agent.target_position.distance_squared_to(pos) < 0.12:
		return
	_queued_nav = pos
	_has_queued_nav = true


func _flush_nav(delta: float) -> void:
	_repath_t = maxf(0.0, _repath_t - delta)
	if not _has_queued_nav or _repath_t > 0.0:
		return
	if _agent.target_position.distance_squared_to(_queued_nav) >= 0.12:
		_agent.target_position = _queued_nav
	_repath_t = _repath_interval
	_has_queued_nav = false


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
	await get_tree().create_timer(2.5, false).timeout
	queue_free()
