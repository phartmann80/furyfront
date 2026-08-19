class_name DepotKit
extends RefCounted
## Visual-only Ironfall pieces. Collision and nav stay on IronfallBuilder hulls.

const _GatePresentation := preload("res://scripts/maps/gate_presentation.gd")

var _mats: Dictionary = {}


func decorate_gate(root: Node3D) -> void:
	var kit := Node3D.new()
	kit.name = "GateKit"
	root.add_child(kit)
	_floor_plates(kit)
	_wall_cladding(kit)
	_security_doorway(kit)
	_sandbags(kit)
	_crates(kit)
	_barriers(kit)
	_signage(kit)
	_branding(kit)
	_fence(kit)
	_cameras(kit)
	_lights(kit)
	_courtyard_fill(kit)
	_watch_and_wires(kit)
	var pres = _GatePresentation.new()
	pres.name = "GatePresentation"
	kit.add_child(pres)


func _mat(key: String, color: Color, metallic: float = 0.0, roughness: float = 0.82, emission: Color = Color(0, 0, 0, 1)) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emission.a > 0.0 and emission.get_luminance() > 0.01:
		m.emission_enabled = true
		m.emission = Color(emission.r, emission.g, emission.b)
		m.emission_energy_multiplier = 1.4
	_mats[key] = m
	return m


func _mesh(parent: Node3D, named: String, size: Vector3, pos: Vector3, mat: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = named
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if GraphicsProfile.tier == GraphicsProfile.Tier.LOW else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func _floor_plates(kit: Node3D) -> void:
	var concrete := _mat("concrete", Color(0.32, 0.31, 0.29), 0.04, 0.92)
	var slab := _mat("concrete_slab", Color(0.36, 0.35, 0.32), 0.05, 0.88)
	var metal := _mat("metal_floor", Color(0.2, 0.21, 0.22), 0.62, 0.42)
	var paint := _mat("lane", Color(0.22, 0.22, 0.2), 0.08, 0.7)
	_mesh(kit, "GateApron", Vector3(18, 0.04, 10), Vector3(0, 0.02, 32.5), concrete)
	_mesh(kit, "ApronSeamA", Vector3(0.08, 0.05, 9.6), Vector3(-3.0, 0.03, 32.5), slab)
	_mesh(kit, "ApronSeamB", Vector3(0.08, 0.05, 9.6), Vector3(3.0, 0.03, 32.5), slab)
	_mesh(kit, "LaneL", Vector3(0.12, 0.05, 8.2), Vector3(-1.15, 0.035, 32.4), paint)
	_mesh(kit, "LaneR", Vector3(0.12, 0.05, 8.2), Vector3(1.15, 0.035, 32.4), paint)
	_mesh(kit, "GateThreshold", Vector3(6.2, 0.06, 1.4), Vector3(0, 0.04, 34.1), metal)
	for i in range(8):
		_mesh(kit, "Grate_%d" % i, Vector3(5.6, 0.03, 0.08), Vector3(0, 0.07, 33.55 + i * 0.14), metal)


func _security_doorway(kit: Node3D) -> void:
	var steel := _mat("steel", Color(0.18, 0.19, 0.2), 0.7, 0.38)
	var frame := _mat("frame", Color(0.12, 0.13, 0.14), 0.65, 0.4)
	# Opening between GateLeft/GateRight stays walkable; frames sit on the jambs.
	_mesh(kit, "DoorJambL", Vector3(0.28, 3.2, 0.42), Vector3(-3.15, 1.6, 34.05), frame)
	_mesh(kit, "DoorJambR", Vector3(0.28, 3.2, 0.42), Vector3(3.15, 1.6, 34.05), frame)
	_mesh(kit, "DoorLintel", Vector3(6.6, 0.32, 0.5), Vector3(0, 3.22, 34.05), steel)
	_mesh(kit, "DoorLeafL", Vector3(1.35, 2.6, 0.08), Vector3(-3.85, 1.4, 33.55), steel, 18.0)
	_mesh(kit, "DoorLeafR", Vector3(1.35, 2.6, 0.08), Vector3(3.85, 1.4, 33.55), steel, -18.0)


func _sandbags(kit: Node3D) -> void:
	var bag := _mat("sandbag", Color(0.45, 0.4, 0.28), 0.0, 0.95)
	var spots := [
		Vector3(-4.2, 0.28, 30.2), Vector3(-3.5, 0.28, 30.55), Vector3(-3.8, 0.52, 30.35),
		Vector3(4.2, 0.28, 30.2), Vector3(3.5, 0.28, 30.55), Vector3(3.8, 0.52, 30.35)
	]
	var i := 0
	for s in spots:
		_mesh(kit, "Sandbag%d" % i, Vector3(0.7, 0.28, 0.38), s, bag)
		i += 1


func _crates(kit: Node3D) -> void:
	var wood := _mat("crate", Color(0.38, 0.28, 0.16), 0.0, 0.88)
	var stencil := _mat("crate_mark", Color(0.22, 0.32, 0.22), 0.05, 0.7)
	_mesh(kit, "CrateA", Vector3(0.9, 0.7, 0.9), Vector3(-7.2, 0.38, 31.4), wood)
	_mesh(kit, "CrateB", Vector3(0.7, 0.55, 0.7), Vector3(-7.15, 0.98, 31.35), wood)
	_mesh(kit, "CrateMark", Vector3(0.92, 0.08, 0.08), Vector3(-7.2, 0.62, 31.86), stencil)
	_mesh(kit, "CrateC", Vector3(0.85, 0.65, 0.85), Vector3(7.4, 0.35, 31.1), wood)


func _wall_cladding(kit: Node3D) -> void:
	var panel := _mat("clad", Color(0.28, 0.29, 0.28), 0.18, 0.62)
	var seam := _mat("clad_seam", Color(0.16, 0.17, 0.16), 0.4, 0.45)
	for side in [-1.0, 1.0]:
		_mesh(kit, "CladA", Vector3(4.6, 2.4, 0.08), Vector3(side * 8.0, 1.35, 33.28), panel)
		_mesh(kit, "CladCap", Vector3(4.8, 0.12, 0.14), Vector3(side * 8.0, 2.62, 33.32), seam)
		_mesh(kit, "CladBolt", Vector3(0.08, 0.08, 0.1), Vector3(side * 6.2, 2.2, 33.36), seam)


func _barriers(kit: Node3D) -> void:
	var concrete := _mat("jersey", Color(0.4, 0.39, 0.36), 0.03, 0.9)
	var cap := _mat("jersey_cap", Color(0.3, 0.3, 0.28), 0.08, 0.7)
	_mesh(kit, "BarrierL", Vector3(2.4, 0.85, 0.42), Vector3(-6.2, 0.42, 27.8), concrete, 12.0)
	_mesh(kit, "BarrierLCap", Vector3(2.5, 0.1, 0.48), Vector3(-6.2, 0.88, 27.8), cap, 12.0)
	_mesh(kit, "BarrierR", Vector3(2.4, 0.85, 0.42), Vector3(6.2, 0.42, 27.8), concrete, -12.0)
	_mesh(kit, "BarrierRCap", Vector3(2.5, 0.1, 0.48), Vector3(6.2, 0.88, 27.8), cap, -12.0)
	_mesh(kit, "CoverBlock", Vector3(1.6, 1.05, 0.48), Vector3(-2.2, 0.52, 29.6), concrete)


func _signage(kit: Node3D) -> void:
	var panel := _mat("sign", Color(0.12, 0.13, 0.12), 0.2, 0.55)
	var amber := _mat("sign_lit", Color(0.08, 0.08, 0.07), 0.1, 0.4, Color(0.85, 0.55, 0.12))
	_mesh(kit, "SignPanel", Vector3(1.8, 0.55, 0.06), Vector3(0, 2.55, 33.72), panel)
	_mesh(kit, "SignBar", Vector3(1.55, 0.12, 0.04), Vector3(0, 2.55, 33.76), amber)


func _branding(kit: Node3D) -> void:
	var steel := _mat("ff_mark", Color(0.18, 0.19, 0.18), 0.35, 0.48)
	# Fury Front F as silhouette bars — not a painted faction band.
	_mesh(kit, "FFStem", Vector3(0.1, 0.7, 0.05), Vector3(-0.22, 2.05, 33.55), steel)
	_mesh(kit, "FFTop", Vector3(0.42, 0.1, 0.05), Vector3(0.02, 2.35, 33.55), steel)
	_mesh(kit, "FFMid", Vector3(0.3, 0.09, 0.05), Vector3(-0.02, 2.08, 33.55), steel)
	_mesh(kit, "Plaque", Vector3(1.2, 0.22, 0.04), Vector3(0, 1.55, 33.52), steel)


func _fence(kit: Node3D) -> void:
	var post := _mat("fence", Color(0.16, 0.17, 0.16), 0.6, 0.42)
	for x in [-12.0, -6.0, 6.0, 12.0]:
		_mesh(kit, "FencePost_%d" % int(x), Vector3(0.12, 2.4, 0.12), Vector3(x, 1.2, 41.35), post)
		_mesh(kit, "FenceRail_%d" % int(x), Vector3(5.4, 0.06, 0.04), Vector3(x + (3.0 if x < 0.0 else -3.0), 1.8, 41.35), post)


func _cameras(kit: Node3D) -> void:
	var housing := _mat("cam", Color(0.08, 0.08, 0.09), 0.4, 0.35)
	var lens := _mat("cam_lens", Color(0.05, 0.08, 0.1), 0.2, 0.2, Color(0.15, 0.45, 0.55))
	for side in [-1.0, 1.0]:
		var arm := _mesh(kit, "CamArm", Vector3(0.08, 0.08, 0.55), Vector3(side * 7.6, 2.85, 33.4), housing)
		arm.rotation_degrees.y = 20.0 * side
		_mesh(kit, "CamBody", Vector3(0.18, 0.14, 0.28), Vector3(side * 7.85, 2.72, 33.15), housing)
		_mesh(kit, "CamLens", Vector3(0.1, 0.1, 0.08), Vector3(side * 7.85, 2.72, 32.98), lens)


func _lights(kit: Node3D) -> void:
	var housing := _mat("lamp", Color(0.2, 0.2, 0.18), 0.5, 0.4)
	_mesh(kit, "LampL", Vector3(0.22, 0.12, 0.35), Vector3(-4.8, 3.35, 33.6), housing)
	_mesh(kit, "LampR", Vector3(0.22, 0.12, 0.35), Vector3(4.8, 3.35, 33.6), housing)


func _courtyard_fill(kit: Node3D) -> void:
	# Visual only. Keep the gate mouth (-3..3 at z≈34) and staging lane clear.
	var hesco := _mat("hesco", Color(0.42, 0.38, 0.28), 0.02, 0.94)
	var rust := _mat("drum", Color(0.28, 0.16, 0.08), 0.18, 0.62)
	var pallet := _mat("pallet", Color(0.34, 0.24, 0.14), 0.0, 0.9)
	var cone := _mat("cone", Color(0.62, 0.28, 0.08), 0.04, 0.7)
	var chev := _mat("chevron", Color(0.55, 0.42, 0.10), 0.06, 0.55)
	for i in range(4):
		_mesh(kit, "HescoL_%d" % i, Vector3(1.15, 1.05, 1.15), Vector3(-10.4, 0.52, 29.2 + i * 1.35), hesco)
		_mesh(kit, "HescoR_%d" % i, Vector3(1.15, 1.05, 1.15), Vector3(10.4, 0.52, 29.2 + i * 1.35), hesco)
	for i in range(3):
		_mesh(kit, "DrumL_%d" % i, Vector3(0.42, 0.72, 0.42), Vector3(-8.6, 0.38, 28.4 + i * 0.55), rust)
		_mesh(kit, "DrumR_%d" % i, Vector3(0.42, 0.72, 0.42), Vector3(8.8, 0.38, 28.2 + i * 0.55), rust)
	_mesh(kit, "PalletA", Vector3(1.2, 0.14, 0.8), Vector3(-8.9, 0.08, 31.9), pallet, 8.0)
	_mesh(kit, "PalletB", Vector3(1.2, 0.14, 0.8), Vector3(-8.9, 0.22, 31.9), pallet, 8.0)
	_mesh(kit, "PalletC", Vector3(1.15, 0.14, 0.75), Vector3(8.6, 0.08, 32.4), pallet, -12.0)
	for i in range(5):
		_mesh(kit, "Chevron_%d" % i, Vector3(0.55, 0.02, 0.16), Vector3(-2.4 + i * 1.2, 0.045, 31.1), chev)
	_mesh(kit, "ConeL", Vector3(0.22, 0.55, 0.22), Vector3(-3.6, 0.28, 32.2), cone)
	_mesh(kit, "ConeR", Vector3(0.22, 0.55, 0.22), Vector3(3.6, 0.28, 32.2), cone)
	var bag := _mat("sandbag", Color(0.45, 0.4, 0.28), 0.0, 0.95)
	for i in range(4):
		_mesh(kit, "BagRowL_%d" % i, Vector3(0.62, 0.24, 0.34), Vector3(-5.1 + (i % 2) * 0.35, 0.22 + int(i / 2) * 0.24, 28.6 + i * 0.12), bag)
		_mesh(kit, "BagRowR_%d" % i, Vector3(0.62, 0.24, 0.34), Vector3(5.1 - (i % 2) * 0.35, 0.22 + int(i / 2) * 0.24, 28.6 + i * 0.12), bag)


func _watch_and_wires(kit: Node3D) -> void:
	var steel := _mat("steel", Color(0.18, 0.19, 0.2), 0.7, 0.38)
	var cable := _mat("cable", Color(0.08, 0.08, 0.08), 0.15, 0.55)
	var lamp := _mat("flood", Color(0.22, 0.22, 0.2), 0.45, 0.4)
	# Watchtower at (10, 6, 30) is a hull; this is cladding only.
	_mesh(kit, "TowerClad", Vector3(4.15, 3.4, 0.08), Vector3(10.0, 3.4, 27.95), steel)
	_mesh(kit, "TowerCladR", Vector3(0.08, 3.4, 4.15), Vector3(12.05, 3.4, 30.0), steel)
	_mesh(kit, "FloodPoleL", Vector3(0.12, 4.2, 0.12), Vector3(-11.6, 2.1, 33.8), steel)
	_mesh(kit, "FloodHeadL", Vector3(0.55, 0.18, 0.35), Vector3(-11.6, 4.28, 33.55), lamp)
	_mesh(kit, "FloodPoleR", Vector3(0.12, 4.2, 0.12), Vector3(11.6, 2.1, 33.8), steel)
	_mesh(kit, "FloodHeadR", Vector3(0.55, 0.18, 0.35), Vector3(11.6, 4.28, 33.55), lamp)
	for i in range(6):
		_mesh(kit, "Cable_%d" % i, Vector3(9.5, 0.04, 0.04), Vector3(0.0, 3.05, 33.22 + i * 0.06), cable)
	var post := _mat("fence", Color(0.16, 0.17, 0.16), 0.6, 0.42)
	for x in [-18.0, 18.0]:
		_mesh(kit, "FenceWing_%d" % int(x), Vector3(0.12, 2.4, 0.12), Vector3(x, 1.2, 41.35), post)
		_mesh(kit, "FenceWingRail_%d" % int(x), Vector3(5.6, 0.06, 0.04), Vector3(x + (2.8 if x < 0.0 else -2.8), 1.8, 41.35), post)
	for i in range(8):
		_mesh(kit, "Razor_%d" % i, Vector3(4.8, 0.05, 0.05), Vector3(-9.6 + i * 2.4, 2.42, 41.38), post)

