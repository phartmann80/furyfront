class_name HitscanSystem
extends Node

func fire(w: Dictionary, origin: Vector3, dir: Vector3, _muzzle: Vector3) -> void:
	var space := get_viewport().world_3d.direct_space_state
	var to := origin + dir.normalized() * 180.0
	if w.get("fireMode", "") == "melee":
		to = origin + dir.normalized() * float(w.get("lungeM", 1.8))
	var q := PhysicsRayQueryParameters3D.create(origin, to)
	q.collision_mask = PhysLayers.WORLD | PhysLayers.ENEMY | PhysLayers.HEAD | PhysLayers.LIMB
	q.collide_with_areas = true
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		VfxBus.tracer(origin, to)
		return
	var pos: Vector3 = hit.position as Vector3
	VfxBus.tracer(origin, pos)
	var collider: Object = hit.collider
	var hitbox := "chest"
	if collider is Area3D:
		if collider.is_in_group("hit_head"):
			hitbox = "head"
		elif collider.is_in_group("hit_limb"):
			hitbox = "limb"
		collider = collider.get_parent()
	var flesh := collider != null and collider.has_method("receive_hit")
	VfxBus.impact(pos, hit.normal, flesh)
	AudioDirector.impact(pos)
	var range_m := origin.distance_to(pos)
	var result := CombatMath.apply_hit(w, range_m, hitbox, 0.0)
	if collider and collider.has_method("receive_hit"):
		var out: Dictionary = collider.receive_hit(float(result.applied), hitbox, origin)
		EventBus.hit_confirmed.emit(hitbox == "head", bool(out.get("killed", false)))
		if bool(out.get("killed", false)):
			EventBus.enemy_killed.emit(str(out.get("id", "sb")))
