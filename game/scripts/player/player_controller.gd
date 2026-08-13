class_name PlayerController
extends CharacterBody3D

const WALK := 4.2
const SPRINT := 6.2
const CROUCH_SPEED := 2.2
const JUMP_V := 7.2
const GRAVITY := 22.0
const HEIGHT_STAND := 1.8
const HEIGHT_CROUCH := 1.15

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


func _ready() -> void:
	add_to_group("player")
	collision_layer = PhysLayers.PLAYER
	collision_mask = PhysLayers.WORLD | PhysLayers.ENEMY | PhysLayers.COVER
	GameState.reset_combat()
	health.setup(GameState.max_health, GameState.armor, "fury_front")
	health.changed.connect(_on_health)
	health.died.connect(_on_died)
	camera.fov = _base_fov
	weapons.setup(["ar_kf16", "smg_wasp", "pis_k5", "ml_knife"])


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_look(delta)
	_move(delta)
	_ads(delta)
	weapons.tick(delta, InputService.is_fire(), InputService.is_ads())
	if Input.is_action_just_pressed("reload"):
		weapons.reload()
	if Input.is_action_just_pressed("weapon_next"):
		weapons.cycle()
	if Input.is_action_just_pressed("grenade"):
		weapons.throw_grenade()
	if Input.is_action_just_pressed("tactical"):
		weapons.throw_tactical()
	if Input.is_action_just_pressed("debug_reset"):
		debug_reset()
	_interact()


func _look(_delta: float) -> void:
	var d := InputService.consume_look()
	yaw -= d.x
	pitch -= d.y
	pitch = clampf(pitch, -1.25, 1.25)
	rotation.y = yaw
	head.rotation.x = pitch


func _move(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		if _try_vault():
			return
		velocity.y = JUMP_V
	crouching = InputService.is_crouch()
	var shape := capsule.shape as CapsuleShape3D
	if shape:
		shape.height = HEIGHT_CROUCH if crouching else HEIGHT_STAND
	var wish := InputService.move_vector()
	var dir := (transform.basis * Vector3(wish.x, 0, -wish.y)).normalized()
	var speed := WALK
	var w := weapons.current()
	speed *= float(w.get("move", 1.0))
	if InputService.is_sprint() and not InputService.is_ads() and not crouching:
		speed = SPRINT * float(w.get("move", 1.0))
	if crouching:
		speed = CROUCH_SPEED
	if ads_t > 0.5:
		speed *= 0.72
	if dir.length() > 0.01:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	move_and_slide()


func _ads(delta: float) -> void:
	var target := 1.0 if InputService.is_ads() else 0.0
	var ads_ms := float(weapons.current().get("adsMs", 240))
	var rate := 1000.0 / maxf(ads_ms, 1.0)
	ads_t = move_toward(ads_t, target, rate * delta)
	camera.fov = lerpf(_base_fov, _base_fov * 0.78, ads_t)
	weapons.set_ads_visual(ads_t)


func _try_vault() -> bool:
	if _vaulting or not vault_ray.is_colliding():
		return false
	var hit := vault_ray.get_collision_point()
	if hit.y - global_position.y > 1.45:
		return false
	_vaulting = true
	var dest := global_position + -transform.basis.z * 1.2
	dest.y = hit.y + 0.1
	var tw := create_tween()
	tw.tween_property(self, "global_position", dest, 0.28)
	tw.finished.connect(func() -> void: _vaulting = false)
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
	if GameState.debug_invuln:
		return
	health.apply_damage(amount)
	GameState.health = health.health
	GameState.armor = health.armor


func _on_health(h: int, a: int) -> void:
	GameState.health = h
	GameState.armor = a
	EventBus.player_damaged.emit(h, a)


func _on_died() -> void:
	_dead = true
	EventBus.player_died.emit()
	await get_tree().create_timer(2.0).timeout
	debug_reset()


func debug_reset() -> void:
	global_transform = GameState.spawn_xform
	_dead = false
	GameState.reset_combat()
	health.setup(GameState.max_health, GameState.armor, "fury_front")
	weapons.refill()
	velocity = Vector3.ZERO
