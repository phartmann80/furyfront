class_name CombatMath
extends RefCounted

static func damage_at_range(w: Dictionary, range_m: float) -> float:
	var dmax := float(w.get("damageMax", 0))
	var dmin := float(w.get("damageMin", 0))
	var a := float(w.get("falloffStart", 0))
	var b := float(w.get("falloffEnd", 1))
	if range_m <= a:
		return dmax
	if range_m >= b:
		return dmin
	var t: float = (range_m - a) / maxf(b - a, 0.0001)
	return lerpf(dmax, dmin, t)


static func hitbox_mul(w: Dictionary, hitbox: String) -> float:
	if hitbox == "head":
		return float(w.get("head", 1.0))
	if hitbox == "limb":
		return float(w.get("limb", 1.0))
	return 1.0


static func apply_hit(w: Dictionary, range_m: float, hitbox: String, armor_absorb: float) -> Dictionary:
	var pellet := damage_at_range(w, range_m) * hitbox_mul(w, hitbox)
	var raw := pellet * float(w.get("pelletCount", 1))
	var applied: float = maxf(0.0, raw - armor_absorb)
	return { "raw": raw, "applied": applied }


static func interval_s(w: Dictionary) -> float:
	var rpm := float(w.get("rpm", 600))
	return 60.0 / maxf(rpm, 1.0)


static func fire_legal(w: Dictionary, last_fire_s: float, now_s: float) -> bool:
	return now_s - last_fire_s >= interval_s(w) * 0.92
