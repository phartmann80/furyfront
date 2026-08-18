extends Node3D
## V0.2 second visual gate. Loads V2 GLBs. Does not touch Ironfall collision/nav.

const ASSAULT := "res://assets/v02/ff_op_assault.glb"
const PHANTOM := "res://assets/v02/ff_sb_phantom.glb"
const KF16 := "res://assets/v02/ff_wpn_kf16.glb"
const ARMS := "res://assets/v02/ff_fps_arms.glb"

var _cam: Camera3D
var _sun: DirectionalLight3D
var _fill: OmniLight3D
var _rim: OmniLight3D
var _env: Environment
var _assault: Node3D
var _phantom: Node3D
var _stand_gun: Node3D
var _fps_hold: Node3D
var _fps_gun: Node3D
var _fps_arms: Node3D
var _studio_fps: Node3D
var _hud: Label
var _ironfall := false
var _view := 0
var _yard: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_env_setup()
	_yard_slice()
	_assault = _inst(ASSAULT)
	_assault.position = Vector3(-1.6, 0.0, 0.0)
	add_child(_assault)
	_phantom = _inst(PHANTOM)
	_phantom.position = Vector3(0.0, 0.0, -10.0)
	_phantom.rotation_degrees.y = 180.0
	add_child(_phantom)
	_stand_gun = _inst(KF16)
	_stand_gun.position = Vector3(1.7, 1.15, 0.35)
	_stand_gun.rotation_degrees = Vector3(8.0, -35.0, 0.0)
	add_child(_stand_gun)
	_cam = Camera3D.new()
	_cam.current = true
	_cam.fov = 50.0
	add_child(_cam)
	_fps_hold = Node3D.new()
	_fps_hold.name = "FpsHold"
	_cam.add_child(_fps_hold)
	_fps_gun = _inst(KF16)
	# Arms are authored in weapon-local space. Parent them so hip and ADS share one grip.
	_fps_hold.add_child(_fps_gun)
	_fps_arms = _inst(ARMS)
	_fps_gun.add_child(_fps_arms)
	_fps_arms.position = Vector3.ZERO
	_set_fps_pose(false)
	_fps_hold.visible = false
	_studio_fps = Node3D.new()
	_studio_fps.name = "StudioFps"
	add_child(_studio_fps)
	var studio_gun := _inst(KF16)
	_studio_fps.add_child(studio_gun)
	var studio_arms := _inst(ARMS)
	studio_gun.add_child(studio_arms)
	studio_arms.position = Vector3.ZERO
	_studio_fps.position = Vector3(0.0, 1.15, 0.0)
	_studio_fps.visible = false
	_hud_setup()
	_apply_view(0)
	if OS.get_environment("FF_V02_GRIP") == "1":
		await _capture_grip()
		get_tree().quit(0)
	if OS.get_environment("FF_V02_CAPTURE") == "1":
		await _capture_all()
		get_tree().quit(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_apply_view(0)
			KEY_2:
				_apply_view(1)
			KEY_3:
				_apply_view(2)
			KEY_4:
				_apply_view(3)
			KEY_5:
				_apply_view(4)
			KEY_6:
				_apply_view(5)
			KEY_7:
				_apply_view(6)
			KEY_8:
				_apply_view(15)
			KEY_9:
				_apply_view(16)
			KEY_N, KEY_I:
				_set_ironfall(not _ironfall)
			KEY_W:
				var vp := get_viewport()
				if vp.debug_draw == Viewport.DEBUG_DRAW_WIREFRAME:
					vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED
				else:
					vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME


func _process(_delta: float) -> void:
	if _hud == null:
		return
	var draws := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	_hud.text = "V2 visual gate  |  %s  |  %s  |  %.0f FPS  |  draw %d\n1-7 views  8 ADS  9 intersect   N/I lighting" % [
		_view_name(_view),
		"Ironfall lighting" if _ironfall else "Neutral inspection",
		Engine.get_frames_per_second(),
		draws,
	]


func _apply_view(idx: int) -> void:
	_view = idx
	_assault.position = Vector3(-1.6, 0.0, 0.0)
	_phantom.position = Vector3(0.0, 0.0, -10.0)
	_phantom.rotation_degrees.y = 180.0
	_fps_hold.visible = idx in [5, 15]
	_studio_fps.visible = idx in [16, 20, 21]
	_assault.visible = idx in [0, 1, 2, 7, 8, 9]
	_phantom.visible = idx in [3, 4, 9, 12, 13, 14, 17, 18]
	_stand_gun.visible = idx in [0, 6, 7, 8, 10, 11, 19]
	_cam.fov = 50.0
	_set_fps_pose(idx == 15)
	match idx:
		0:
			_look(Vector3(-1.6, 1.35, 3.2), Vector3(-1.6, 1.15, 0.0))
		1:
			_cam.fov = 35.0
			_look(Vector3(-1.6, 1.72, 0.85), Vector3(-1.6, 1.7, 0.0))
		2:
			_cam.fov = 32.0
			_look(Vector3(-1.6, 1.28, 0.7), Vector3(-1.6, 1.22, 0.12))
		3:
			_look(Vector3(0.0, 1.4, 1.5), Vector3(0.0, 1.1, -10.0))
		4:
			_cam.fov = 32.0
			_look(Vector3(0.0, 1.55, -8.6), Vector3(0.0, 1.45, -10.0))
		5:
			_cam.fov = 75.0
			_cam.position = Vector3(0.0, 1.6, 2.4)
			_cam.rotation = Vector3(0.0, 0.0, 0.0)
		6:
			_cam.fov = 28.0
			_look(Vector3(1.95, 1.22, 0.85), Vector3(1.7, 1.15, 0.35))
		7:
			_look(Vector3(-0.2, 1.35, 3.4), Vector3(-1.6, 1.15, 0.0))
		8:
			_look(Vector3(-1.6, 1.35, -3.2), Vector3(-1.6, 1.15, 0.0))
		9:
			_cam.fov = 45.0
			_look(Vector3(0.0, 1.4, 3.6), Vector3(0.0, 1.1, 0.0))
			_assault.position = Vector3(-0.7, 0.0, 0.0)
			_phantom.position = Vector3(0.7, 0.0, 0.0)
			_phantom.rotation_degrees.y = 0.0
			_stand_gun.visible = false
		10:
			_cam.fov = 32.0
			_look(Vector3(1.55, 1.18, 0.15), Vector3(1.7, 1.15, 0.35))
		11:
			_cam.fov = 32.0
			_look(Vector3(1.85, 1.18, 0.55), Vector3(1.7, 1.15, 0.35))
		12:
			_phantom.position = Vector3(0.0, 0.0, 0.0)
			_phantom.rotation_degrees.y = 0.0
			_look(Vector3(0.0, 1.35, 3.2), Vector3(0.0, 1.15, 0.0))
		13:
			_phantom.position = Vector3(0.0, 0.0, 0.0)
			_phantom.rotation_degrees.y = 0.0
			_look(Vector3(2.1, 1.35, 2.6), Vector3(0.0, 1.15, 0.0))
		14:
			_phantom.position = Vector3(0.0, 0.0, 0.0)
			_phantom.rotation_degrees.y = 0.0
			_look(Vector3(0.0, 1.35, -3.2), Vector3(0.0, 1.15, 0.0))
		15:
			_cam.fov = 75.0
			_cam.position = Vector3(0.0, 1.6, 2.4)
			_cam.rotation = Vector3(0.0, 0.0, 0.0)
		16:
			_cam.fov = 32.0
			_look(Vector3(0.22, 1.18, 0.16), Vector3(0.02, 1.10, -0.04))
		17:
			_phantom.position = Vector3(0.0, 0.0, 0.0)
			_phantom.rotation_degrees.y = 0.0
			_cam.fov = 35.0
			_look(Vector3(0.0, 1.68, 0.80), Vector3(0.0, 1.64, 0.0))
		18:
			_phantom.position = Vector3(0.0, 0.0, 0.0)
			_phantom.rotation_degrees.y = 0.0
			_cam.fov = 32.0
			_look(Vector3(0.0, 1.22, 0.65), Vector3(0.0, 1.16, 0.08))
		19:
			_cam.fov = 24.0
			_look(Vector3(1.82, 1.18, 0.48), Vector3(1.70, 1.16, 0.32))
		20:
			_cam.fov = 28.0
			_look(Vector3(0.10, 1.12, 0.08), Vector3(0.01, 1.10, 0.02))
		21:
			_cam.fov = 28.0
			_look(Vector3(-0.10, 1.20, -0.08), Vector3(0.00, 1.17, -0.18))


func _look(from: Vector3, at: Vector3) -> void:
	_cam.position = from
	_cam.look_at(at, Vector3.UP)


func _view_name(idx: int) -> String:
	var names := [
		"Assault full",
		"Assault helmet close",
		"Assault kit close",
		"Phantom mid (10m)",
		"Phantom close",
		"FPS arms + KF-16",
		"KF-16 hero close",
		"Assault 3/4",
		"Assault back",
		"Silhouette compare",
		"KF-16 left",
		"KF-16 right",
		"Phantom front",
		"Phantom 3/4",
		"Phantom back",
		"FPS ADS two-hand",
		"FPS intersection",
		"Phantom helmet close",
		"Phantom kit close",
		"KF-16 receiver close",
		"FPS trigger close",
		"FPS support close",
	]
	return names[idx] if idx >= 0 and idx < names.size() else "view"


func _set_fps_pose(ads: bool) -> void:
	if _fps_gun == null:
		return
	if ads:
		_fps_gun.position = Vector3(0.0, -0.135, -0.36)
	else:
		_fps_gun.position = Vector3(0.22, -0.19, -0.40)


func _set_ironfall(on: bool) -> void:
	_ironfall = on
	if _yard:
		_yard.visible = on
	if on:
		_env.background_color = Color(0.16, 0.18, 0.2)
		_env.ambient_light_color = Color(0.38, 0.4, 0.42)
		_env.ambient_light_energy = 0.55
		_env.fog_enabled = true
		_env.fog_light_color = Color(0.22, 0.24, 0.26)
		_env.fog_density = 0.006
		_sun.rotation_degrees = Vector3(-42, 35, 0)
		_sun.light_energy = 1.15
		_sun.light_color = Color(1.0, 0.92, 0.82)
		_fill.light_energy = 0.35
		_rim.light_energy = 0.2
	else:
		_env.background_color = Color(0.12, 0.13, 0.14)
		_env.ambient_light_color = Color(0.42, 0.44, 0.46)
		_env.ambient_light_energy = 0.4
		_env.fog_enabled = false
		_sun.rotation_degrees = Vector3(-28, 25, 0)
		_sun.light_energy = 1.35
		_sun.light_color = Color(1, 1, 1)
		_fill.light_energy = 1.4
		_rim.light_energy = 0.9


func _env_setup() -> void:
	var w := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	w.environment = _env
	add_child(w)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = false
	add_child(_sun)
	_fill = OmniLight3D.new()
	_fill.position = Vector3(-2.2, 2.6, 2.8)
	_fill.omni_range = 14.0
	_fill.shadow_enabled = false
	add_child(_fill)
	_rim = OmniLight3D.new()
	_rim.position = Vector3(2.4, 2.2, -2.0)
	_rim.omni_range = 12.0
	_rim.light_color = Color(0.75, 0.82, 0.9)
	_rim.shadow_enabled = false
	add_child(_rim)
	_set_ironfall(false)


func _yard_slice() -> void:
	_yard = Node3D.new()
	_yard.name = "YardSlice"
	add_child(_yard)
	var conc := _mat(Color(0.34, 0.33, 0.31), 0.05, 0.9)
	var steel := _mat(Color(0.2, 0.21, 0.22), 0.62, 0.4)
	var mark := _mat(Color(0.16, 0.17, 0.16), 0.15, 0.55)
	_box(_yard, "Apron", Vector3(8, 0.03, 14), Vector3(0, -0.01, -4), conc)
	_box(_yard, "WallL", Vector3(0.35, 2.8, 6), Vector3(-4.2, 1.4, -8.5), steel)
	_box(_yard, "WallR", Vector3(0.35, 2.8, 6), Vector3(4.2, 1.4, -8.5), steel)
	_box(_yard, "CoverL", Vector3(1.6, 0.85, 0.38), Vector3(-2.4, 0.42, -3.2), conc)
	_box(_yard, "CoverR", Vector3(1.6, 0.85, 0.38), Vector3(2.4, 0.42, -3.2), conc)
	_box(_yard, "FFBar1", Vector3(0.08, 0.55, 0.04), Vector3(-0.18, 1.9, -5.48), mark)
	_box(_yard, "FFBar2", Vector3(0.32, 0.08, 0.04), Vector3(-0.02, 2.12, -5.48), mark)
	_box(_yard, "FFBar3", Vector3(0.24, 0.08, 0.04), Vector3(-0.02, 1.9, -5.48), mark)
	_yard.visible = false


func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


func _box(parent: Node3D, named: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = named
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _hud_setup() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(24, 20)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)


func _inst(path: String) -> Node3D:
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("missing " + path)
		return Node3D.new()
	return ps.instantiate() as Node3D


func _capture_grip() -> void:
	_set_ironfall(false)
	var shots := [
		[5, "gate_fps_kf16.png"],
		[15, "gate_fps_ads.png"],
		[20, "gate_fps_trigger.png"],
		[21, "gate_fps_support.png"],
		[5, "gate_fps_intersect.png"],
	]
	for item in shots:
		_apply_view(int(item[0]))
		await get_tree().create_timer(0.40, true).timeout
		await _save_png(str(item[1]))
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	_apply_view(5)
	await get_tree().create_timer(0.40, true).timeout
	await _save_png("gate_fps_wire.png")
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	_apply_view(5)
	await get_tree().create_timer(1.0, true).timeout
	_write_stats()
	print("grip checkpoint capture ok")


func _capture_all() -> void:
	var shots := [
		[0, false, "gate_assault.png"],
		[7, false, "gate_assault_34.png"],
		[8, false, "gate_assault_back.png"],
		[1, false, "gate_assault_helmet.png"],
		[2, false, "gate_assault_kit.png"],
		[12, false, "gate_phantom.png"],
		[13, false, "gate_phantom_34.png"],
		[14, false, "gate_phantom_back.png"],
		[3, false, "gate_phantom_mid.png"],
		[4, false, "gate_phantom_close.png"],
		[9, false, "gate_silhouette.png"],
		[5, false, "gate_fps_kf16.png"],
		[15, false, "gate_fps_ads.png"],
		[16, false, "gate_fps_intersect.png"],
		[6, false, "gate_kf16_hero.png"],
		[10, false, "gate_kf16_left.png"],
		[11, false, "gate_kf16_right.png"],
		[19, false, "gate_kf16_receiver.png"],
		[17, false, "gate_phantom_helmet.png"],
		[18, false, "gate_phantom_kit.png"],
		[0, true, "gate_assault_ironfall.png"],
		[3, true, "gate_phantom_ironfall.png"],
	]
	for item in shots:
		_set_ironfall(bool(item[1]))
		_apply_view(int(item[0]))
		await get_tree().create_timer(0.35, true).timeout
		await _save_png(str(item[2]))
	_set_ironfall(false)
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	_apply_view(0)
	await get_tree().create_timer(0.35, true).timeout
	await _save_png("gate_assault_wire.png")
	_apply_view(12)
	await get_tree().create_timer(0.35, true).timeout
	await _save_png("gate_phantom_wire.png")
	_apply_view(6)
	await get_tree().create_timer(0.35, true).timeout
	await _save_png("gate_kf16_wire.png")
	_apply_view(5)
	await get_tree().create_timer(0.35, true).timeout
	await _save_png("gate_fps_wire.png")
	_apply_view(16)
	await get_tree().create_timer(0.35, true).timeout
	await _save_png("gate_fps_intersect_wire.png")
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	_apply_view(0)
	await get_tree().create_timer(2.0, true).timeout
	_write_stats()
	print("visual gate capture ok")


func _save_png(fname: String) -> void:
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("no viewport image")
		return
	var abs_dir := ProjectSettings.globalize_path("res://assets/v02/shots")
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var dest := abs_dir.path_join(fname)
	var err := img.save_png(dest)
	print("saved ", dest, " err=", err, " ", img.get_width(), "x", img.get_height())


func _write_stats() -> void:
	var draws := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	var arms_node: Node = _fps_arms if _fps_arms else _fps_hold
	var payload := {
		"version": "v2",
		"assault_tris": _tris(_assault),
		"phantom_tris": _tris(_phantom),
		"kf16_tris": _tris(_stand_gun),
		"fps_arms_tris": _tris(arms_node),
		"materials_assault": _mats(_assault),
		"materials_phantom": _mats(_phantom),
		"materials_kf16": _mats(_stand_gun),
		"surfaces_assault": _surfaces(_assault),
		"surfaces_phantom": _surfaces(_phantom),
		"surfaces_kf16": _surfaces(_stand_gun),
		"kf16_nodes": _names(_stand_gun),
		"draw_calls": draws,
		"fps": Engine.get_frames_per_second(),
		"window": [1920, 1080],
	}
	var f := FileAccess.open("res://assets/v02/godot_import_stats.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print("godot stats ", payload)


func _tris(n: Node) -> int:
	var t := 0
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var arr: Array = mi.mesh.surface_get_arrays(s)
				var indices = arr[Mesh.ARRAY_INDEX]
				if indices:
					t += int(indices.size() / 3)
				elif arr[Mesh.ARRAY_VERTEX]:
					t += int(arr[Mesh.ARRAY_VERTEX].size() / 3)
	for c in n.get_children():
		t += _tris(c)
	return t


func _surfaces(n: Node) -> int:
	var t := 0
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			t += mi.mesh.get_surface_count()
	for c in n.get_children():
		t += _surfaces(c)
	return t


func _names(n: Node, acc: Array = []) -> Array:
	acc.append(str(n.name))
	for c in n.get_children():
		_names(c, acc)
	return acc


func _mats(n: Node) -> int:
	var s := {}
	_collect_mats(n, s)
	return s.size()


func _collect_mats(n: Node, s: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(i)
				s[str(mat)] = true
	for c in n.get_children():
		_collect_mats(c, s)
