class_name MissionDirector
extends Node

var phase: String = "cinematic"
var integrity: float = 100.0
var transfer: float = 0.0
var restored := false
var map: Dictionary = {}
var _spawns: Node
var _elapsed := 0.0

func start(world: Node, markers: Dictionary) -> void:
	map = markers
	_spawns = world
	integrity = 100.0
	transfer = 0.0
	_set_phase("cinematic")
	EventBus.alarm_started.connect(_on_alarm)
	var restore := world.get_node_or_null("RestoreStation")
	if restore:
		restore.used.connect(_on_restored)


func _process(delta: float) -> void:
	_elapsed += delta
	match phase:
		"cinematic":
			if _elapsed > float(ContentCatalog.mission.get("cinematicS", 22)):
				_set_phase("staging")
		"staging":
			if _elapsed > 2.0:
				_set_phase("alarm")
		"alarm":
			AudioDirector.alarm()
			AudioDirector.radio("FURY FRONT: BREACH AT THE GATE.")
			_set_phase("checkpoint")
			_wave(["sb_phantom", "sb_phantom"], "gate", "recruit")
		"checkpoint":
			integrity -= 1.2 * delta
			if _enemies() <= 0 or _elapsed > 25.0:
				_set_phase("command")
				_wave(["sb_phantom", "sb_phantom", "sb_enforcer"], "command", "trained")
		"command":
			integrity -= 2.0 * delta
			if _elapsed > 12.0:
				_set_phase("grid_down")
		"grid_down":
			integrity -= 3.5 * delta
			EventBus.notify.emit("SECURITY GRID DISABLED")
			if _elapsed > 4.0:
				_set_phase("engineer")
		"engineer":
			integrity -= 1.5 * delta
			if restored:
				_set_phase("grid_up")
		"grid_up":
			integrity = minf(100.0, integrity + 4.0 * delta)
			if _elapsed > 4.0:
				_set_phase("data_steal")
				_wave(["sb_hacker", "sb_hacker", "sb_phantom"], "server", "trained")
		"data_steal":
			if _hackers_alive():
				transfer += 4.0 * delta
			if transfer >= 100.0:
				_fail()
			elif _enemies() <= 0 or _elapsed > 28.0:
				_set_phase("extraction")
				_wave(["sb_enforcer", "sb_phantom", "sb_hacker"], "extraction", "veteran")
		"extraction":
			if _elapsed > 20.0 or _enemies() <= 1:
				_set_phase("commander")
				_wave(["sb_commander", "sb_enforcer"], "extraction", "elite")
		"commander":
			if _enemies() <= 0:
				_set_phase("collapse")
		"collapse":
			if _elapsed > 3.0:
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
		"staging": "MOVE TO STAGING",
		"alarm": "SECURITY BREACH",
		"checkpoint": "DEFEND THE GATE",
		"command": "COMMAND CENTER — DEFEND",
		"grid_down": "GRID DOWN — REACH COMMS",
		"engineer": "RESTORE SECURITY SYSTEM",
		"grid_up": "GRID RESTORED",
		"data_steal": "STOP DATA THEFT — SERVER ROOM",
		"extraction": "INTERCEPT EXTRACTION LZ",
		"commander": "ELIMINATE SHADOWBREAKER COMMANDER",
		"collapse": "AREA SECURE",
		"results": "MISSION COMPLETE",
	}
	EventBus.objective_changed.emit(str(labels.get(p, p)))


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
		e.global_position = origin + Vector3(randf_range(-4, 4), 1.0, randf_range(-4, 4))
		var pts: Array[Vector3] = [
			origin + Vector3(-6, 0, 0),
			origin + Vector3(6, 0, 0),
			origin + Vector3(0, 0, -6),
		]
		e.setup(str(ids[i]), skill, pts)
	VfxBus.breach_distortion()


func _enemies() -> int:
	return get_tree().get_nodes_in_group("shadowbreakers").size()


func _hackers_alive() -> bool:
	for n in get_tree().get_nodes_in_group("shadowbreakers"):
		if n is Shadowbreaker and (n as Shadowbreaker).archetype_id == "sb_hacker":
			return true
	return false


func _on_alarm() -> void:
	pass


func _on_restored(_id: String) -> void:
	restored = true


func _win() -> void:
	phase = "results"
	GameState.mission_success = true
	EventBus.mission_ended.emit(true)
	set_process(false)


func _fail() -> void:
	phase = "results"
	GameState.mission_success = false
	EventBus.mission_ended.emit(false)
	EventBus.objective_changed.emit("MISSION FAILED")
	set_process(false)
