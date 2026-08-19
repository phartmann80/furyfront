class_name V02Visuals
extends RefCounted
## Loads V0.2 clay GLBs into the play path. Collision/nav stay on the V0.1 hulls.

const ASSAULT := "res://assets/v02/ff_op_assault.glb"
const ASSAULT_LOD2 := "res://assets/v02/ff_op_assault_lod2.glb"
const PHANTOM := "res://assets/v02/ff_sb_phantom.glb"
const PHANTOM_LOD2 := "res://assets/v02/ff_sb_phantom_lod2.glb"
const KF16 := "res://assets/v02/ff_wpn_kf16.glb"
const ARMS := "res://assets/v02/ff_fps_arms.glb"

# hm08 chest is Blender -Y → Godot +Z after glTF Y-up. CharacterBody3D look_at uses -Z.
const CHARACTER_YAW := 180.0


static func instance_scene(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	return ps.instantiate() as Node3D


static func character(assault: bool) -> Node3D:
	# Combat workhorse is LOD2 for every 3P body so a wave stays inside the triangle cap.
	var path := ASSAULT_LOD2 if assault else PHANTOM_LOD2
	var n := instance_scene(path)
	if n == null:
		path = ASSAULT if assault else PHANTOM
		n = instance_scene(path)
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
