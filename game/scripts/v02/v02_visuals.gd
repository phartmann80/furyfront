class_name V02Visuals
extends RefCounted
## Loads V0.2 GLBs into the play path and applies ship materials. Collision/nav stay on V0.1 hulls.

const ASSAULT := "res://assets/v02/ff_op_assault.glb"
const ASSAULT_LOD2 := "res://assets/v02/ff_op_assault_lod2.glb"
const PHANTOM := "res://assets/v02/ff_sb_phantom.glb"
const PHANTOM_LOD2 := "res://assets/v02/ff_sb_phantom_lod2.glb"
const KF16 := "res://assets/v02/ff_wpn_kf16.glb"
const ARMS := "res://assets/v02/ff_fps_arms.glb"

const TEX_WEAVE := "res://assets/v02/mat/tex_weave.png"
const TEX_GRIT := "res://assets/v02/mat/tex_grit.png"
const TEX_LEATHER := "res://assets/v02/mat/tex_leather.png"
const TEX_VISOR := "res://assets/v02/mat/tex_visor.png"
const TEX_POLY := "res://assets/v02/mat/tex_poly.png"
const TEX_METAL := "res://assets/v02/mat/tex_metal.png"

# hm08 chest is Blender -Y → Godot +Z after glTF Y-up. CharacterBody3D look_at uses -Z.
const CHARACTER_YAW := 180.0

static var _cache: Dictionary = {}


static func instance_scene(path: String, kind: String = "") -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var n := ps.instantiate() as Node3D
	if n and kind != "":
		dress(n, kind)
	return n


static func character(assault: bool) -> Node3D:
	# Combat workhorse is LOD2 for every 3P body so a wave stays inside the triangle cap.
	var path := ASSAULT_LOD2 if assault else PHANTOM_LOD2
	var kind := "assault" if assault else "phantom"
	var n := instance_scene(path, kind)
	if n == null:
		path = ASSAULT if assault else PHANTOM
		n = instance_scene(path, kind)
	if n == null:
		return null
	n.rotation_degrees.y = CHARACTER_YAW
	return n


static func named(root: Node, n: String) -> Node:
	if root == null:
		return null
	if root.name == n:
		return root
	return root.find_child(n, true, false)


static func dress(root: Node, kind: String) -> void:
	_walk_dress(root, kind)


static func _walk_dress(n: Node, kind: String) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var src := mi.mesh.surface_get_material(i)
				var slot := _slot_name(src, kind)
				mi.set_surface_override_material(i, _material(kind, slot))
	for c in n.get_children():
		_walk_dress(c, kind)


static func _slot_name(src: Material, kind: String) -> String:
	var nm := ""
	if src:
		nm = str(src.resource_name).to_lower()
	if "visor" in nm:
		return "visor"
	if "armor" in nm:
		return "armor"
	if "glove" in nm or "sleeve" in nm:
		return "glove"
	if "fabric" in nm:
		return "fabric"
	if "metal" in nm:
		return "metal"
	if "poly" in nm:
		return "poly"
	if kind == "weapon":
		return "metal"
	if kind == "arms":
		return "glove"
	return "fabric"


static func _material(kind: String, slot: String) -> StandardMaterial3D:
	var key := kind + "/" + slot
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3(2.4, 2.4, 2.4)
	match slot:
		"armor":
			m.albedo_texture = _tex(TEX_GRIT)
			if kind == "phantom":
				m.albedo_color = Color(0.14, 0.16, 0.18)
				m.metallic = 0.34
				m.roughness = 0.38
			else:
				m.albedo_color = Color(0.24, 0.25, 0.22)
				m.metallic = 0.22
				m.roughness = 0.48
		"visor":
			m.albedo_texture = _tex(TEX_VISOR)
			m.uv1_scale = Vector3(1.4, 1.4, 1.4)
			if kind == "phantom":
				m.albedo_color = Color(0.06, 0.12, 0.14)
				m.metallic = 0.78
				m.roughness = 0.12
				m.emission_enabled = true
				m.emission = Color(0.08, 0.22, 0.26)
				m.emission_energy_multiplier = 0.85
			else:
				m.albedo_color = Color(0.08, 0.09, 0.10)
				m.metallic = 0.72
				m.roughness = 0.16
		"glove":
			m.albedo_texture = _tex(TEX_LEATHER)
			m.uv1_scale = Vector3(3.0, 3.0, 3.0)
			if kind == "phantom":
				m.albedo_color = Color(0.10, 0.10, 0.11)
			else:
				m.albedo_color = Color(0.36, 0.26, 0.16)
			m.metallic = 0.04
			m.roughness = 0.72
		"metal":
			m.albedo_texture = _tex(TEX_METAL)
			m.albedo_color = Color(0.55, 0.56, 0.58)
			m.metallic = 0.82
			m.roughness = 0.34
			m.uv1_scale = Vector3(3.2, 3.2, 3.2)
		"poly":
			m.albedo_texture = _tex(TEX_POLY)
			m.albedo_color = Color(0.12, 0.12, 0.13)
			m.metallic = 0.06
			m.roughness = 0.64
		_:
			m.albedo_texture = _tex(TEX_WEAVE)
			if kind == "phantom":
				m.albedo_color = Color(0.16, 0.18, 0.20)
			else:
				m.albedo_color = Color(0.32, 0.33, 0.26)
			m.metallic = 0.04
			m.roughness = 0.78
	_cache[key] = m
	return m


static func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
