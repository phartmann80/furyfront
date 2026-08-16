class_name PlayerController
extends CharacterBody3D

const WALK := 4.4
const SPRINT := 6.6
const CROUCH_SPEED := 2.15
const JUMP_V := 7.0
const GRAVITY := 24.0
const HEIGHT_STAND := 1.8
const HEIGHT_CROUCH := 1.15
const ACCEL_GROUND := 22.0
const DECEL_GROUND := 16.0
const ACCEL_AIR := 5.5
const AIR_CONTROL := 0.42
const HEAD_STAND_Y := 1.62
const HEAD_CROUCH_Y := 1.05

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var capsule: CollisionShape3D = $Collision
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var vault_ray: RayCast3D = $VaultRay
@onready var weapons: WeaponManager = $Head/Camera3D/WeaponManager
@onready var health: HealthComponent = $HealthComponent

var yaw := 0.0
var pitch := 0.0
var crouching := false
var ads_t := 0.0
var _base_fov := 75.0
var _dead := false
var _vaulting := false
var _height := HEIGHT_STAND
var _head_y := HEAD_STAND_Y
var _bob_t := 0.0
var _bob_y := 0.0
var _land_ofs := 0.0
var _was_air := false
var _step_t := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = PhysLayers.PLAYER
	collision_mask = PhysLayers.WORLD | PhysLayers.ENEMY | PhysLayers.COVER
	GameState.reset_run()
	health.setup(GameState.max_health, GameState.armor, "fury_front")
	health.changed.connect(_on_health)
	health.died.connect(_on_died)
	camera.fov = _base_fov
	weapons.setup(["ar_kf16", "smg_wasp", "pis_k5", "ml_knife"])


func _physics_process(delta: float) -> void:
	if _dead or GameState.mission_over:
		return
	_look(delta)
	_move(delta)
	_ads(delta)
	weapons.tick(delta, InputService.is_fire(), InputService.is_ads(), velocity)
	if Input.is_action_just_pressed("reload"):
		weapons.reload()
	if Input.is_action_just_pressed("weapon_next"):
		weapons.cycle()
	if Input.is_action_just_pressed("grenade"):
		weapons.throw_grenade()
	if Input.is_action_just_pressed("tactical"):
		weapons.throw_tactical()
	if Input.is_action_just_pressed("debug_reset"):
		respawn()
	_interact()


func _look(_delta: float) -> void:
	var d := InputService.consume_look()
	yaw -= d.x
	pitch -= d.y
	pitch = clampf(pitch, -1.25, 1.25)
	rotation.y = yaw + weapons.recoil_yaw
	head.rotation.x = pitch + weapons.recoil_pitch + _land_ofs + _bob_y


func _move(delta: float) -> void:
	if _vaulting:
		return
	var grounded := is_on_floor()
	if not grounded:
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		if _try_vault():
			return
		velocity.y = JUMP_V
		grounded = false
	if grounded and _was_air and velocity.y < -6.0:
		_land_ofs = -0.045
		AudioDirector.footstep(global_position, "land")
	_was_air = not grounded
	_land_ofs = move_toward(_land_ofs, 0.0, delta * 0.22)

	crouching = InputService.is_crouch()
	var want_h := HEIGHT_CROUCH if crouching else HEIGHT_STAND
	var want_head := HEAD_CROUCH_Y if crouching else HEAD_STAND_Y
	_height = move_toward(_height, want_h, delta * 8.0)
	_head_y = move_toward(_head_y, want_head, delta * 8.0)
	var shape := capsule.shape as CapsuleShape3D
	if shape:
		shape.height = _height
		capsule.position.y = _height * 0.5
	head.position.y = _head_y

	var wish := InputService.move_vector()
	var dir := (transform.basis * Vector3(wish.x, 0, -wish.y))
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	elif dir.length_squared() > 0.0001:
		dir = dir.normalized() * dir.length()
	else:
		dir = Vector3.ZERO

	var w := weapons.current()
	var speed := WALK * float(w.get("move", 1.0))
	var sprinting := InputService.is_sprint() and not InputService.is_ads() and not crouching and dir.dot(-transform.basis.z) > 0.15
	if sprinting:
		speed = SPRINT * float(w.get("move", 1.0))
	if crouching:
		speed = CROUCH_SPEED
	if ads_t > 0.45:
		speed *= 0.68

	var target := Vector3(dir.x * speed, 0.0, dir.z * speed)
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if grounded:
		var rate := ACCEL_GROUND if dir.length() > 0.08 else DECEL_GROUND
		horiz = horiz.move_toward(target, rate * delta)
	else:
		if dir.length() > 0.08:
			horiz = horiz.move_toward(target, ACCEL_AIR * AIR_CONTROL * delta)
		horiz *= 1.0 - (0.12 * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z
	move_and_slide()
	_bob(delta, grounded, sprinting, horiz.length())


func _bob(delta: float, grounded: bool, sprinting: bool, speed: float) -> void:
	if grounded and speed > 1.2:
		_bob_t += delta * (8.5 if sprinting else 6.4) * (speed / WALK)
		var amp := 0.011 * (0.35 if ads_t > 0.5 else 1.0)
		if sprinting:
			amp *= 1.15
		_bob_y = sin(_bob_t) * amp
		_step_t += delta * (speed / WALK)
		if _step_t > 0.48:
			_step_t = 0.0
			AudioDirector.footstep(global_position, "step")
	else:
		_bob_y = move_toward(_bob_y, 0.0, delta * 0.08)
		_bob_t = 0.0


func _ads(delta: float) -> void:
	var target := 1.0 if InputService.is_ads() else 0.0
	var ads_ms := float(weapons.current().get("adsMs", 240))
	var rate := 1000.0 / maxf(ads_ms, 1.0)
	ads_t = move_toward(ads_t, target, rate * delta)
	var sprint_fov := 6.0 if InputService.is_sprint() and ads_t < 0.2 and velocity.length() > 4.5 else 0.0
	camera.fov = lerpf(_base_fov + sprint_fov, _base_fov * 0.76, ads_t)
	weapons.set_ads_visual(ads_t)


func _try_vault() -> bool:
	if _vaulting or not vault_ray.is_colliding():
		return false
	var hit := vault_ray.get_collision_point()
	var rise := hit.y - global_position.y
	if rise < 0.35 or rise > 1.35:
		return false
	_vaulting = true
	var dest := global_position + -transform.basis.z * 1.15
	dest.y = hit.y + 0.12
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", dest, 0.26)
	tw.finished.connect(func() -> void:
		_vaulting = false
		velocity.y = 0.0
	)
	return true


func _interact() -> void:
	if interact_ray.is_colliding():
		var n := interact_ray.get_collider()
		if n and n.has_meta("interact"):
			EventBus.interact_available.emit(str(n.get_meta("interact")))
			if Input.is_action_pressed("interact"):
				if n.has_method("interact"):
					n.interact(self)
			return
	EventBus.interact_available.emit("")


func take_hit(amount: float, _from: Vector3) -> void:
	if GameState.mission_over or GameState.debug_invuln:
		return
	health.apply_damage(amount)
	GameState.health = health.health
	GameState.armor = health.armor
	_land_ofs = minf(_land_ofs, -0.02)


func _on_health(h: int, a: int) -> void:
	GameState.health = h
	GameState.armor = a
	EventBus.player_damaged.emit(h, a)


func _on_died() -> void:
	_dead = true
	EventBus.player_died.emit()
	await get_tree().create_timer(2.0, false).timeout
	if not is_instance_valid(self) or GameState.mission_over or get_tree().paused:
		return
	respawn()


func respawn() -> void:
	global_transform = GameState.spawn_xform
	_dead = false
	GameState.reset_life()
	health.setup(GameState.max_health, GameState.armor, "fury_front")
	weapons.refill()
	velocity = Vector3.ZERO
	ads_t = 0.0
	_land_ofs = 0.0
	_bob_y = 0.0
	_vaulting = false
