extends Node

func muzzle(pos: Vector3, _dir: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.35)
	l.light_energy = 4.0 * GraphicsProfile.particle_scale
	l.omni_range = 3.5
	l.shadow_enabled = false
	get_tree().current_scene.add_child(l)
	l.global_position = pos
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(l):
		l.queue_free()


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


func impact(pos: Vector3, normal: Vector3) -> void:
	if not GraphicsProfile.decal_enabled:
		return
	# Decal nodes are unreliable on Compatibility/web. Use a world-aligned quad.
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.15, 0.14, 0.12, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + normal * 0.02
	if normal.length_squared() > 0.001:
		mi.look_at(pos + normal, Vector3.UP)
	await get_tree().create_timer(8.0).timeout
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
