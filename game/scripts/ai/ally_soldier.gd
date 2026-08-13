class_name AllySoldier
extends CharacterBody3D

var health: HealthComponent

func setup(origin: Vector3) -> void:
	add_to_group("allies")
	collision_layer = PhysLayers.PLAYER
	collision_mask = PhysLayers.WORLD | PhysLayers.ENEMY
	global_position = origin
	health = HealthComponent.new()
	add_child(health)
	health.setup(100, 15, "fury_front")
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	mi.mesh = cm
	mi.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.32, 0.22)
	mi.material_override = mat
	add_child(mi)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var to := player.global_position - global_position
		to.y = 0
		if to.length() > 4.5:
			var d := to.normalized()
			velocity.x = d.x * 4.0
			velocity.z = d.z * 4.0
		else:
			velocity.x = 0
			velocity.z = 0
	move_and_slide()
