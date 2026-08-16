class_name MissionDirector
extends Node

var phase: String = "cinematic"
var integrity: float = 100.0
var transfer: float = 0.0
var restored := false
var map: Dictionary = {}
var _spawns: Node
var _elapsed := 0.0
var _extract_s := 0.0
var _alarmed := false
var _comms_hint_played := false

func start(world: Node, markers: Dictionary) -> void:
	map = markers
	_spawns = world
	integrity = 100.0
	transfer = 0.0
	_set_phase("cinematic")
	EventBus.enemy_killed.connect(_on_kill)
	var restore := world.get_node_or_null("RestoreStation")
	if restore:
		restore.used.connect(_on_restored)


func _process(delta: float) -> void:
	_elapsed += delta
	GameState.mission_clock += delta
	match phase:
		"cinematic":
			if _elapsed > float(ContentCatalog.mission.get("cinematicS", 14)):
				_set_phase("staging")
		"staging":
			if _elapsed > 2.0:
				_set_phase("alarm")
		"alarm":
			if not _alarmed:
				_alarmed = true
				AudioDirector.alarm()
				EventBus.alarm_started.emit()
				AudioDirector.radio("FURY FRONT: BREACH AT THE GATE. HOLD IRONFALL.")
			_set_phase("checkpoint")
			_wave(["sb_phantom", "sb_phantom"], "spawn_gate", "recruit")
		"checkpoint":
			integrity -= 0.28 * delta
			if _enemies() <= 0 or _elapsed > 42.0:
				_set_phase("command")
				_wave(["sb_phantom", "sb_phantom", "sb_enforcer"], "spawn_command", "trained")
		"command":
			integrity -= 0.42 * delta
			if _enemies() <= 0 or _elapsed > 38.0:
				_set_phase("grid_down")
		"grid_down":
			integrity -= 0.9 * delta
			if _elapsed > 2.5:
				_set_phase("engineer")
		"engineer":
			integrity -= 0.38 * delta
			if restored:
				_set_phase("grid_up")
			elif not _comms_hint_played and _elapsed >= 8.0:
				_comms_hint_played = true
				AudioDirector.radio("COMMS: Restore panel is at the Comms doorway. Hold E.")
		"grid_up":
			integrity = minf(100.0, integrity + 8.0 * delta)
			if _elapsed > 2.5:
				_set_phase("data_steal")
				_wave(["sb_hacker", "sb_hacker", "sb_phantom"], "spawn_server", "trained")
		"data_steal":
			if _hackers_alive():
				transfer += 1.15 * delta
			if transfer >= 100.0:
				_fail()
			elif not _hackers_alive() and _elapsed > 1.5:
				_set_phase("extraction")
				_extract_s = 55.0
				_wave(["sb_enforcer", "sb_phantom", "sb_hacker"], "spawn_extraction", "veteran")
		"extraction":
			_extract_s = maxf(0.0, _extract_s - delta)
			EventBus.extraction_changed.emit(_extract_s)
			if _enemies() <= 1:
				_set_phase("commander")
				_wave(["sb_commander", "sb_enforcer"], "spawn_extraction", "elite")
			elif _extract_s <= 0.0:
				_fail()
		"commander":
			if _enemies() <= 0 or _elapsed > 50.0:
				_set_phase("collapse")
		"collapse":
			if _elapsed > 2.5:
				_win()
	integrity = clampf(integrity, 0.0, 100.0)
	transfer = clampf(transfer, 0.0, 100.0)
	EventBus.integrity_changed.emit(integrity)
	EventBus.transfer_changed.emit(transfer)
	if integrity <= 0.0 and phase != "results":
		_fail()


func _set_phase(p: String) -> void:
	phase = p
	_elapsed = 0.0
	EventBus.mission_phase.emit(p)
	var labels := {
		"cinematic": "IRONFALL DEPOT — STAND BY",
		"staging": "MOVE TO STAGING — LOAD KF-16",
		"alarm": "SECURITY BREACH",
		"checkpoint": "DEFEND THE GATE",
		"command": "DEFEND THE COMMAND CENTER",
		"grid_down": "GRID DOWN — REACH COMMS",
		"engineer": "HOLD [E] — RESTORE SECURITY GRID",
		"grid_up": "GRID RESTORED",
		"data_steal": "STOP THE SIGNAL HACKER — SERVER ROOM",
		"extraction": "INTERCEPT EXTRACTION TEAM",
		"commander": "ELIMINATE SHADOWBREAKER COMMANDER",
		"collapse": "AREA SECURE",
		"results": "MISSION COMPLETE",
	}
	var briefs := {
		"cinematic": "Fury Front holds Ironfall Depot. Shadowbreakers want the intel.",
		"staging": "You are the reaction element. Command center is the heart of the base.",
		"alarm": "Perimeter is compromised. If the gate falls, they reach command.",
		"checkpoint": "Stop the first wave at the security gate.",
		"command": "Do not let them occupy the command floor.",
		"grid_down": "Cameras and locks are down. Integrity is bleeding.",
		"engineer": "Restore the grid at Comms or the base stays blind.",
		"grid_up": "Sensors back online. They will go for the server next.",
		"data_steal": "Hackers are stealing classified traffic. Kill them or we lose the data.",
		"extraction": "Stop the steal team at the LZ before they leave with the packet.",
		"commander": "Their commander is covering the extract. Drop him.",
		"collapse": "Ironfall holds.",
		"results": "",
	}
	EventBus.objective_changed.emit(str(labels.get(p, p)))
	EventBus.briefing_changed.emit(str(briefs.get(p, "")))
	_sync_objective(p)
	_radio_for(p)


func _sync_objective(p: String) -> void:
	var keys := {
		"checkpoint": "gate",
		"alarm": "gate",
		"command": "command",
		"grid_down": "comms",
		"engineer": "comms",
		"grid_up": "server",
		"data_steal": "server",
		"extraction": "extraction",
		"commander": "extraction",
		"staging": "staging",
	}
	if not keys.has(p):
		return
	var key := str(keys[p])
	if not map.has(key):
		return
	var raw: Variant = map[key]
	if raw is Transform3D:
		GameState.objective_pos = (raw as Transform3D).origin
	elif raw is Vector3:
		GameState.objective_pos = raw


func _radio_for(p: String) -> void:
	match p:
		"command":
			AudioDirector.radio("ACTUAL: Command center is the prize. Do not give it up.")
		"grid_down":
			AudioDirector.radio("COMMS: Grid just died. Get to the restore panel.")
		"data_steal":
			AudioDirector.radio("INTEL: They are on the servers. Kill the hackers.")
		"extraction":
			AudioDirector.radio("ACTUAL: Extract inbound. Do not let that packet leave.")
		"commander":
			AudioDirector.radio("ACTUAL: Commander on the LZ. Finish it.")
		"collapse":
			AudioDirector.radio("ACTUAL: Ironfall is secure. Good work.")


func _wave(ids: Array, marker: String, skill: String) -> void:
	var raw: Variant = map.get(marker, Vector3.ZERO)
	var origin := Vector3.ZERO
	if raw is Transform3D:
		origin = (raw as Transform3D).origin
	elif raw is Vector3:
		origin = raw
	for i in ids.size():
		var e := Shadowbreaker.new()
		_spawns.add_child(e)
		e.global_position = origin + Vector3(randf_range(-2.2, 2.2), 0.0, randf_range(-2.2, 2.2))
		var pts: Array[Vector3] = [
			origin + Vector3(-7, 0, 0),
			origin + Vector3(7, 0, 0),
			origin + Vector3(0, 0, -7),
			origin + Vector3(-4, 0, 5),
		]
		e.setup(str(ids[i]), skill, pts)
	VfxBus.breach_distortion()


func _enemies() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("shadowbreakers"):
		if node is Shadowbreaker and not (node as Shadowbreaker).health.dead:
			n += 1
	return n


func _hackers_alive() -> bool:
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n is Shadowbreaker:
			var sb := n as Shadowbreaker
			if sb.archetype_id == "sb_hacker" and not sb.health.dead:
				return true
	return false


func _on_kill(_id: String) -> void:
	GameState.kills += 1


func _on_restored(_id: String) -> void:
	restored = true


func _win() -> void:
	phase = "results"
	GameState.mission_success = true
	GameState.mission_over = true
	EventBus.mission_ended.emit(true)
	set_process(false)


func _fail() -> void:
	phase = "results"
	GameState.mission_success = false
	GameState.mission_over = true
	EventBus.mission_ended.emit(false)
	EventBus.objective_changed.emit("MISSION FAILED")
	EventBus.briefing_changed.emit("The depot is lost. Integrity collapsed or the packet left Ironfall.")
	set_process(false)
