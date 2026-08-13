class_name IronfallBuilder
extends RefCounted

var markers: Dictionary = {}

func build(root: Node3D) -> void:
	_env(root)
	_floor(root)
	_building(root, "CommandCenter", Vector3(0, 2.5, 0), Vector3(14, 5, 12), Color(0.32, 0.34, 0.36))
	_building(root, "Barracks", Vector3(26, 2.0, 8), Vector3(12, 4, 10), Color(0.35, 0.3, 0.28))
	_building(root, "Armory", Vector3(-26, 2.0, 8), Vector3(10, 4, 10), Color(0.28, 0.3, 0.32))
	_building(root, "Comms", Vector3(-20, 1.8, -14), Vector3(8, 3.6, 8), Color(0.25, 0.36, 0.4))
	_building(root, "ServerIntel", Vector3(20, 1.8, -14), Vector3(10, 3.6, 8), Color(0.2, 0.28, 0.34))
	var srv := root.get_node("ServerIntel")
	srv.add_to_group("objective_server")
	_building(root, "Watchtower", Vector3(10, 6.0, 30), Vector3(4, 12, 4), Color(0.4, 0.38, 0.32))
	_wall(root, "GateLeft", Vector3(-8, 1.5, 34), Vector3(10, 3, 1.2))
	_wall(root, "GateRight", Vector3(8, 1.5, 34), Vector3(10, 3, 1.2))
	_wall(root, "PerimeterN", Vector3(0, 1.5, 42), Vector3(80, 3, 0.8))
	_wall(root, "PerimeterS", Vector3(0, 1.5, -48), Vector3(80, 3, 0.8))
	_wall(root, "PerimeterE", Vector3(40, 1.5, -3), Vector3(0.8, 3, 90))
	_wall(root, "PerimeterW", Vector3(-40, 1.5, -3), Vector3(0.8, 3, 90))
	_corridor(root)
	_cover(root)
	_interact_points(root)
	_nav(root)
	markers["staging"] = Transform3D(Basis.IDENTITY, Vector3(0, 1.0, 36))
	markers["gate"] = Vector3(0, 0, 32)
	markers["command"] = Vector3(0, 0, 0)
	markers["comms"] = Vector3(-20, 0, -14)
	markers["server"] = Vector3(20, 0, -14)
	markers["extraction"] = Vector3(0, 0, -40)
	markers["yard"] = Vector3(-22, 0, 22)


func _env(root: Node3D) -> void:
	var w := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.2, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.4, 0.42)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = GraphicsProfile.tier != GraphicsProfile.Tier.LOW
	env.fog_enabled = true
	env.fog_light_color = Color(0.22, 0.24, 0.26)
	env.fog_density = 0.004
	w.environment = env
	root.add_child(w)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = GraphicsProfile.shadow_enabled
	root.add_child(sun)


func _floor(root: Node3D) -> void:
	_box(root, "Floor", Vector3(0, -0.15, -4), Vector3(84, 0.3, 96), Color(0.22, 0.23, 0.24), 1)


func _building(root: Node3D, named: String, pos: Vector3, size: Vector3, color: Color) -> void:
	_box(root, named, pos, size, color, 1)
	# interior void: opening on +Z
	_box(root, named + "DoorwayClear", pos + Vector3(0, 0, size.z * 0.5 + 0.4), Vector3(2.2, 2.4, 1.0), Color(0.1, 0.1, 0.1), 0)
	var obs := NavigationObstacle3D.new()
	obs.radius = maxf(size.x, size.z) * 0.45
	obs.height = size.y
	obs.position = pos
	root.add_child(obs)


func _wall(root: Node3D, named: String, pos: Vector3, size: Vector3) -> void:
	_box(root, named, pos, size, Color(0.3, 0.31, 0.3), 1)


func _corridor(root: Node3D) -> void:
	_box(root, "MaintenanceL", Vector3(-3, 1.4, -26), Vector3(0.5, 2.8, 18), Color(0.25, 0.25, 0.26), 1)
	_box(root, "MaintenanceR", Vector3(3, 1.4, -26), Vector3(0.5, 2.8, 18), Color(0.25, 0.25, 0.26), 1)
	_box(root, "Ramp", Vector3(0, 0.4, -34), Vector3(4, 0.8, 6), Color(0.28, 0.28, 0.27), 1)
	_box(root, "ExtractPad", Vector3(0, 0.05, -42), Vector3(12, 0.1, 10), Color(0.45, 0.32, 0.12), 1)


func _cover(root: Node3D) -> void:
	var spots := [
		Vector3(-6, 0.5, 24), Vector3(6, 0.5, 24), Vector3(-10, 0.5, 12),
		Vector3(10, 0.5, 12), Vector3(-8, 0.5, -4), Vector3(8, 0.5, -4),
		Vector3(-14, 0.5, -22), Vector3(14, 0.5, -22), Vector3(-4, 0.5, -38),
		Vector3(4, 0.5, -38), Vector3(-18, 0.5, 20), Vector3(16, 0.5, 18)
	]
	var i := 0
	for s in spots:
		_box(root, "Cover%d" % i, s, Vector3(1.6, 1.0, 0.6), Color(0.38, 0.34, 0.28), PhysLayers.WORLD | PhysLayers.COVER)
		i += 1


func _interact_points(root: Node3D) -> void:
	_station(root, "RestoreStation", Vector3(-20, 1.0, -10), "RESTORE SECURITY GRID")
	_station(root, "CommandConsole", Vector3(0, 1.0, 4), "COMMAND CONSOLE")


func _station(root: Node3D, named: String, pos: Vector3, label: String) -> void:
	var body := StaticBody3D.new()
	body.name = named
	body.collision_layer = PhysLayers.INTERACT
	body.collision_mask = 0
	body.set_meta("interact", label)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.6, 1.2)
	col.shape = box
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.8, 1.4, 0.8)
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.6, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.4, 0.3)
	mi.material_override = mat
	body.add_child(mi)
	body.set_script(load("res://scripts/objectives/interact_station.gd"))
	root.add_child(body)
	body.global_position = pos


func _nav(root: Node3D) -> void:
	var region := NavigationRegion3D.new()
	region.name = "NavRegion"
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.4
	mesh.agent_height = 1.8
	mesh.agent_max_climb = 0.5
	mesh.parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	region.navigation_mesh = mesh
	root.add_child(region)
	# Deferred collider bake avoids GPU mesh stall on Android.
	region.bake_navigation_mesh(true)


func _box(root: Node3D, named: String, pos: Vector3, size: Vector3, color: Color, layer: int) -> void:
	var body := StaticBody3D.new()
	body.name = named
	body.collision_layer = layer
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)
	root.add_child(body)
	body.global_position = pos
