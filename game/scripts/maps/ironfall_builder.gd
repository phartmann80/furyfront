class_name IronfallBuilder
extends RefCounted

var markers: Dictionary = {}

func build(root: Node3D) -> void:
	_env(root)
	# Geometry must be children of the region or the bake parses an empty tree.
	var geo := NavigationRegion3D.new()
	geo.name = "NavRegion"
	root.add_child(geo)
	_floor(geo)
	_building(geo, "CommandCenter", Vector3(0, 2.5, 0), Vector3(14, 5, 12), Color(0.32, 0.34, 0.36))
	_building(geo, "Barracks", Vector3(26, 2.0, 8), Vector3(12, 4, 10), Color(0.35, 0.3, 0.28))
	_building(geo, "Armory", Vector3(-26, 2.0, 8), Vector3(10, 4, 10), Color(0.28, 0.3, 0.32))
	_building(geo, "Comms", Vector3(-20, 1.8, -14), Vector3(8, 3.6, 8), Color(0.25, 0.36, 0.4))
	_building(geo, "ServerIntel", Vector3(20, 1.8, -14), Vector3(10, 3.6, 8), Color(0.2, 0.28, 0.34))
	var srv := Marker3D.new()
	srv.name = "ServerIntel"
	root.add_child(srv)
	srv.global_position = Vector3(20, 1.0, -9.2)
	srv.add_to_group("objective_server")
	_building(geo, "Watchtower", Vector3(10, 6.0, 30), Vector3(4, 12, 4), Color(0.4, 0.38, 0.32))
	_wall(geo, "GateLeft", Vector3(-8, 1.5, 34), Vector3(10, 3, 1.2))
	_wall(geo, "GateRight", Vector3(8, 1.5, 34), Vector3(10, 3, 1.2))
	_wall(geo, "PerimeterN", Vector3(0, 1.5, 42), Vector3(80, 3, 0.8))
	_wall(geo, "PerimeterS", Vector3(0, 1.5, -48), Vector3(80, 3, 0.8))
	_wall(geo, "PerimeterE", Vector3(40, 1.5, -3), Vector3(0.8, 3, 90))
	_wall(geo, "PerimeterW", Vector3(-40, 1.5, -3), Vector3(0.8, 3, 90))
	_corridor(geo)
	_yard(geo)
	_underground(geo)
	_cover(geo)
	_interact_points(root)
	_bake_nav(geo)
	markers["staging"] = Transform3D(Basis.IDENTITY, Vector3(0, 1.0, 36))
	markers["gate"] = Vector3(0, 0, 32)
	markers["command"] = Vector3(0, 0, 8)
	markers["comms"] = Vector3(-20, 0, -9)
	markers["server"] = Vector3(20, 0, -9)
	markers["extraction"] = Vector3(0, 0, -40)
	markers["yard"] = Vector3(-22, 0, 22)
	# Wave spawns sit in courtyards/door mouths, not inside hollow hulls.
	markers["spawn_gate"] = Vector3(0, 1.0, 29)
	markers["spawn_command"] = Vector3(0, 1.0, 9)
	markers["spawn_server"] = Vector3(20, 1.0, -8)
	markers["spawn_extraction"] = Vector3(0, 1.0, -36)


func _env(root: Node3D) -> void:
	var w := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.2, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.4, 0.42)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = false
	env.fog_enabled = GraphicsProfile.tier != GraphicsProfile.Tier.LOW
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
	var t := 0.38
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	_box(root, named + "Floor", pos + Vector3(0, -hy + 0.08, 0), Vector3(size.x, 0.16, size.z), color.darkened(0.12), 1)
	_box(root, named + "Roof", pos + Vector3(0, hy - 0.08, 0), Vector3(size.x, 0.16, size.z), color.darkened(0.05), 1)
	_box(root, named + "WallW", pos + Vector3(-hx + t * 0.5, 0, 0), Vector3(t, size.y, size.z), color, 1)
	_box(root, named + "WallE", pos + Vector3(hx - t * 0.5, 0, 0), Vector3(t, size.y, size.z), color, 1)
	_box(root, named + "WallS", pos + Vector3(0, 0, -hz + t * 0.5), Vector3(size.x, size.y, t), color, 1)
	var door := 2.5
	var jamb := (size.x - door) * 0.5
	if jamb > 0.4:
		_box(root, named + "DoorL", pos + Vector3(-door * 0.5 - jamb * 0.5, 0, hz - t * 0.5), Vector3(jamb, size.y, t), color, 1)
		_box(root, named + "DoorR", pos + Vector3(door * 0.5 + jamb * 0.5, 0, hz - t * 0.5), Vector3(jamb, size.y, t), color, 1)
		_box(root, named + "Lintel", pos + Vector3(0, hy * 0.45, hz - t * 0.5), Vector3(door, size.y * 0.35, t), color, 1)
	var obs := NavigationObstacle3D.new()
	obs.radius = minf(size.x, size.z) * 0.22
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


func _yard(root: Node3D) -> void:
	_box(root, "YardPad", Vector3(-22, 0.04, 22), Vector3(16, 0.08, 14), Color(0.2, 0.21, 0.22), 1)
	_box(root, "TruckA", Vector3(-26, 0.85, 20), Vector3(5.5, 1.6, 2.2), Color(0.22, 0.26, 0.2), 1)
	_box(root, "TruckB", Vector3(-18, 0.75, 24), Vector3(4.8, 1.4, 2.0), Color(0.24, 0.24, 0.2), 1)
	_box(root, "CrateStack", Vector3(-14, 0.7, 18), Vector3(2.2, 1.4, 2.2), Color(0.36, 0.3, 0.2), 1)


func _underground(root: Node3D) -> void:
	_box(root, "UnderRamp", Vector3(8, -0.2, -30), Vector3(3.2, 0.5, 8), Color(0.2, 0.2, 0.21), 1)
	_box(root, "UnderHallL", Vector3(6.4, 0.9, -36), Vector3(0.4, 2.2, 12), Color(0.18, 0.19, 0.2), 1)
	_box(root, "UnderHallR", Vector3(9.6, 0.9, -36), Vector3(0.4, 2.2, 12), Color(0.18, 0.19, 0.2), 1)


func _cover(root: Node3D) -> void:
	var spots := [
		Vector3(-6, 0.5, 24), Vector3(6, 0.5, 24), Vector3(-10, 0.5, 12),
		Vector3(10, 0.5, 12), Vector3(-8, 0.5, -4), Vector3(8, 0.5, -4),
		Vector3(-14, 0.5, -22), Vector3(14, 0.5, -22), Vector3(-4, 0.5, -38),
		Vector3(4, 0.5, -38), Vector3(-18, 0.5, 20), Vector3(16, 0.5, 18),
		Vector3(-4, 0.5, 30), Vector3(4, 0.5, 30), Vector3(0, 0.5, 8)
	]
	var i := 0
	for s in spots:
		var body := _box(root, "Cover%d" % i, s, Vector3(1.6, 1.0, 0.7), Color(0.38, 0.34, 0.28), PhysLayers.WORLD | PhysLayers.COVER)
		body.add_to_group("cover")
		i += 1


func _interact_points(root: Node3D) -> void:
	# Sit in the Comms doorway so the interact ray is not buried in the hull.
	_station(root, "RestoreStation", Vector3(-20, 1.0, -9.0), "RESTORE SECURITY GRID")


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


func _bake_nav(region: NavigationRegion3D) -> void:
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.75
	mesh.agent_max_climb = 0.5
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = PhysLayers.WORLD | PhysLayers.COVER
	region.navigation_mesh = mesh
	# Unthreaded web export cannot bake on a worker thread.
	region.bake_navigation_mesh(false)


func _box(root: Node3D, named: String, pos: Vector3, size: Vector3, color: Color, layer: int) -> StaticBody3D:
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
	return body
