extends Node

func muzzle(pos: Vector3, _dir: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.35)
	l.light_energy = 5.2 * GraphicsProfile.particle_scale
	l.omni_range = 3.8
	l.shadow_enabled = false
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	await get_tree().create_timer(0.045).timeout
	if is_instance_valid(l):
		l.queue_free()


func muzzle_smoke(pos: Vector3, dir: Vector3) -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW:
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
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos
	var tw := mi.create_tween()
	tw.tween_property(mi, "global_position", pos + dir * 0.35 + Vector3.UP * 0.08, 0.22)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	await tw.finished
	if is_instance_valid(mi):
		mi.queue_free()


func shell_eject(pos: Vector3, right: Vector3) -> void:
	if GraphicsProfile.tier == GraphicsProfile.Tier.LOW:
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
	var dest := pos + right * randf_range(0.25, 0.45) + Vector3.UP * randf_range(0.12, 0.28)
	var tw := mi.create_tween()
	tw.tween_property(mi, "global_position", dest, 0.18)
	await tw.finished
	if is_instance_valid(mi):
		mi.queue_free()


func tracer(from: Vector3, to: Vector3) -> void:
	var im := MeshInstance3D.new()
	var imesh := ImmediateMesh.new()
	im.mesh = imesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	im.material_override = mat
	get_tree().current_scene.add_child(im)
	imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	imesh.surface_add_vertex(from)
	imesh.surface_add_vertex(from.lerp(to, 0.92))
	imesh.surface_end()
	await get_tree().create_timer(0.04).timeout
	if is_instance_valid(im):
		im.queue_free()


func impact(pos: Vector3, normal: Vector3, flesh: bool = false) -> void:
	if not GraphicsProfile.decal_enabled and not flesh:
		return
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.18) if flesh else Vector2(0.22, 0.22)
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if flesh:
		mat.albedo_color = Color(0.55, 0.08, 0.08, 0.85)
	else:
		mat.albedo_color = Color(0.15, 0.14, 0.12, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + normal * 0.02
	if normal.length_squared() > 0.001:
		mi.look_at(pos + normal, Vector3.UP)
	await get_tree().create_timer(0.35 if flesh else 8.0).timeout
	if is_instance_valid(mi):
		mi.queue_free()


func explosion(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.12)
	l.light_energy = 8.0
	l.omni_range = 8.0
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	await get_tree().create_timer(0.2).timeout
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
	await get_tree().create_timer(9.5).timeout
	if is_instance_valid(mi):
		mi.queue_free()


func breach_distortion() -> void:
	EventBus.notify.emit("DIMENSIONAL BREACH")
