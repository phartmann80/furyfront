class_name PlayerFactory
extends RefCounted

static func spawn(parent: Node, xform: Transform3D) -> PlayerController:
	var p := PlayerController.new()
	p.name = "Player"
	var col := CollisionShape3D.new()
	col.name = "Collision"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	p.add_child(col)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.6, 0)
	p.add_child(head)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.fov = 75.0
	head.add_child(cam)
	var ir := RayCast3D.new()
	ir.name = "InteractRay"
	ir.target_position = Vector3(0, 0, -3.2)
	ir.collision_mask = PhysLayers.INTERACT
	ir.hit_from_inside = true
	ir.enabled = true
	cam.add_child(ir)
	var wm := WeaponManager.new()
	wm.name = "WeaponManager"
	cam.add_child(wm)
	var vault := RayCast3D.new()
	vault.name = "VaultRay"
	vault.target_position = Vector3(0, 0, -1.1)
	vault.position = Vector3(0, 0.9, 0)
	vault.collision_mask = 1
	p.add_child(vault)
	var hp := HealthComponent.new()
	hp.name = "HealthComponent"
	p.add_child(hp)
	parent.add_child(p)
	p.global_transform = xform
	GameState.spawn_xform = xform
	return p

