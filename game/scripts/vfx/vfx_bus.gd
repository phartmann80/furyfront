extends Node

var _live := 0
var _flash_shader: Shader


func _ready() -> void:
	_flash_shader = load("res://shaders/muzzle_flash.gdshader") as Shader


func muzzle(pos: Vector3, dir: Vector3) -> void:
	if not _can_spawn(2):
		return
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.35)
	l.light_energy = 7.4 * GraphicsProfile.particle_scale
	l.omni_range = 4.4
	l.shadow_enabled = false
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	_live += 1
	var flash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.14) * GraphicsProfile.particle_scale
	flash.mesh = quad
	var mat := ShaderMaterial.new()
	if _flash_shader:
		mat.shader = _flash_shader
		mat.set_shader_parameter("intensity", 5.2 * GraphicsProfile.particle_scale)
		mat.set_shader_parameter("age", 0.0)
	flash.material_override = mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(flash)
	flash.global_position = pos
	if dir.length_squared() > 0.001:
		flash.look_at(pos + dir, Vector3.UP)
	_live += 1
	var tw := flash.create_tween()
	tw.tween_method(func(a: float) -> void:
		if mat:
			mat.set_shader_parameter("age", a)
	, 0.0, 1.0, 0.07)
	await get_tree().create_timer(0.045, false).timeout
	if is_instance_valid(l):
		l.queue_free()
		_live = maxi(_live - 1, 0)
	await tw.finished
	if is_instance_valid(flash):
		flash.queue_free()
		_live = maxi(_live - 1, 0)


func muzzle_smoke(pos: Vector3, dir: Vector3) -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW or not _can_spawn(1):
		return
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.05
	sph.height = 0.1
	mi.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.72, 0.74, 0.35)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	_live += 1
	var tw := mi.create_tween()
	tw.tween_property(mi, "global_position", pos + dir * 0.35 + Vector3.UP * 0.08, 0.22)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	await tw.finished
	_free_fx(mi)


func shell_eject(pos: Vector3, right: Vector3) -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW or not _can_spawn(1):
		return
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.012, 0.012, 0.04)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.62, 0.18)
	mi.material_override = mat
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + Vector3.UP * 0.02
	_live += 1
	var dest := pos + right * randf_range(0.25, 0.45) + Vector3.UP * randf_range(0.12, 0.28)
	var tw := mi.create_tween()
	tw.tween_property(mi, "global_position", dest, 0.18)
	await tw.finished
	_free_fx(mi)


func tracer(from: Vector3, to: Vector3) -> void:
	if not _can_spawn(1):
		return
	var im := MeshInstance3D.new()
	var imesh := ImmediateMesh.new()
	im.mesh = imesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	im.material_override = mat
	im.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(im)
	imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	imesh.surface_add_vertex(from)
	imesh.surface_add_vertex(from.lerp(to, 0.92))
	imesh.surface_end()
	_live += 1
	await get_tree().create_timer(0.04, false).timeout
	_free_fx(im)


func impact(pos: Vector3, normal: Vector3, flesh: bool = false) -> void:
	if not flesh:
		_sparks(pos, normal)
		_dust(pos, normal)
	if not GraphicsProfile.decal_enabled and not flesh:
		return
	if not _can_spawn(1):
		return
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.26, 0.26) if flesh else Vector2(0.22, 0.22)
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if flesh:
		mat.albedo_color = Color(0.55, 0.08, 0.08, 0.85)
	else:
		mat.albedo_color = Color(0.15, 0.14, 0.12, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + normal * 0.02
	if normal.length_squared() > 0.001:
		mi.look_at(pos + normal, Vector3.UP)
	_live += 1
	await get_tree().create_timer(0.35 if flesh else 8.0, false).timeout
	_free_fx(mi)


func explosion(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.12)
	l.light_energy = 8.0
	l.omni_range = 8.0
	l.shadow_enabled = false
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	await get_tree().create_timer(0.2, false).timeout
	if is_instance_valid(l):
		l.queue_free()


func smoke(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 2.8
	sph.height = 5.6
	mi.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55, 0.56, 0.58, 0.45)
	mi.material_override = mat
	mi.add_to_group("smoke_volume")
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + Vector3.UP
	await get_tree().create_timer(9.5, false).timeout
	if is_instance_valid(mi):
		mi.queue_free()


func breach_distortion() -> void:
	EventBus.notify.emit("DIMENSIONAL BREACH")
	var gate := get_tree().get_first_node_in_group("gate_presentation")
	if gate and gate.has_method("pulse_breach"):
		gate.call("pulse_breach")
		return
	var layer := CanvasLayer.new()
	layer.layer = 9
	get_tree().current_scene.add_child(layer)
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.28, 0.1, 0.42, 0.22)
	layer.add_child(overlay)
	await get_tree().create_timer(0.45, false).timeout
	if is_instance_valid(layer):
		layer.queue_free()


func _sparks(pos: Vector3, normal: Vector3) -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW:
		return
	var n := 3 if GraphicsProfile.tier == GraphicsProfile.Tier.MEDIUM else 5
	n = mini(n, GraphicsProfile.particle_cap - _live)
	for i in n:
		if not _can_spawn(1):
			return
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.018, 0.018, 0.04)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.82, 0.35)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.65, 0.15)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_tree().current_scene.add_child(mi)
		mi.global_position = pos
		_live += 1
		var scatter := (normal + Vector3(randf_range(-0.6, 0.6), randf_range(0.2, 0.9), randf_range(-0.6, 0.6))).normalized()
		var tw := mi.create_tween()
		tw.tween_property(mi, "global_position", pos + scatter * randf_range(0.18, 0.42), 0.12)
		tw.tween_callback(_free_fx.bind(mi))


func _dust(pos: Vector3, normal: Vector3) -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW or not _can_spawn(1):
		return
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.07
	sph.height = 0.14
	mi.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.48, 0.45, 0.4, 0.4)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + normal * 0.04
	_live += 1
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(2.2, 2.2, 2.2), 0.28)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.28)
	await tw.finished
	_free_fx(mi)


func _can_spawn(count: int) -> bool:
	return _live + count <= GraphicsProfile.particle_cap


func _free_fx(n: Node) -> void:
	if is_instance_valid(n):
		n.queue_free()
	_live = maxi(_live - 1, 0)
