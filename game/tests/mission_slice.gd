extends Node
## Headless Broken Perimeter phase machine. Run as a scene so autoloads resolve.

func _ready() -> void:
	var fail: PackedStringArray = PackedStringArray()
	var world := Node3D.new()
	world.name = "IronfallDepot"
	add_child(world)
	var builder := IronfallBuilder.new()
	builder.build(world)
	if world.get_node_or_null("ServerIntel") == null:
		fail.append("ServerIntel marker missing")
	if world.get_node_or_null("RestoreStation") == null:
		fail.append("RestoreStation missing")
	var region := world.get_node_or_null("NavRegion") as NavigationRegion3D
	if region == null or region.navigation_mesh == null or region.navigation_mesh.get_polygon_count() < 4:
		fail.append("navmesh did not bake walkable polygons")
	if world.get_node_or_null("CommandConsole") != null:
		fail.append("CommandConsole should not compete with restore")
	if get_tree().get_nodes_in_group("objective_server").is_empty():
		fail.append("objective_server group empty")
	for key in ["spawn_gate", "spawn_command", "spawn_server", "spawn_extraction", "comms"]:
		if not builder.markers.has(key):
			fail.append("marker missing %s" % key)
	var spawn_server: Vector3 = builder.markers.get("spawn_server", Vector3.ZERO)
	if spawn_server.z < -10.0:
		fail.append("server spawn is inside the hull")
	var md := MissionDirector.new()
	add_child(md)
	md.start(world, builder.markers)
	if md.phase != "cinematic":
		fail.append("mission did not start cinematic")
	md._set_phase("engineer")
	md._on_restored("RestoreStation")
	md._process(0.05)
	if md.phase != "grid_up":
		fail.append("restore did not advance engineer got %s" % md.phase)
	md._elapsed = 3.0
	md._process(0.05)
	if md.phase != "data_steal":
		fail.append("grid_up did not reach data_steal got %s" % md.phase)
	_kill_sb()
	md._elapsed = 2.0
	md._process(0.05)
	if md.phase != "extraction":
		fail.append("killing hackers did not start extraction got %s" % md.phase)
	_kill_sb()
	md._process(0.05)
	if md.phase != "commander":
		fail.append("clearing extract wave did not start commander got %s" % md.phase)
	_kill_sb()
	md._process(0.05)
	if md.phase != "collapse":
		fail.append("killing commander did not collapse got %s" % md.phase)
	md._elapsed = 3.0
	md._process(0.05)
	if md.phase != "results" or not GameState.mission_success:
		fail.append("mission did not win")
	if not fail.is_empty():
		push_error("MISSION SLICE FAIL\n" + "\n".join(fail))
		get_tree().quit(1)
		return
	print("mission slice ok")
	get_tree().quit(0)


func _kill_sb() -> void:
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n is Shadowbreaker:
			var sb := n as Shadowbreaker
			if sb.health and not sb.health.dead:
				sb.health.dead = true
