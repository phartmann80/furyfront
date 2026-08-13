extends SceneTree

func _initialize() -> void:
	var fail: PackedStringArray = PackedStringArray()
	var f := FileAccess.open("res://resources/balance/weapons.json", FileAccess.READ)
	if f == null:
		fail.append("weapons.json not imported")
	else:
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		var kf: Dictionary = {}
		for w in data.get("weapons", []):
			if w.get("id") == "ar_kf16":
				kf = w
				break
		if kf.is_empty():
			fail.append("kf16 missing")
		else:
			var dmg := CombatMath.damage_at_range(kf, 10.0)
			if dmg != 28.0:
				fail.append("kf16 damageAt 10m expected 28 got %s" % dmg)
			var head := CombatMath.apply_hit(kf, 10.0, "head", 0.0)
			if float(head.applied) < 38.0:
				fail.append("head modifier failed")
			if not CombatMath.fire_legal(kf, 0.0, 0.08):
				fail.append("rpm gate too strict")
			if CombatMath.fire_legal(kf, 0.0, 0.01):
				fail.append("zero-dt fire should fail")
			var armor_hit := CombatMath.apply_hit(kf, 10.0, "chest", 25.0)
			if float(armor_hit.applied) >= 28.0:
				fail.append("armor absorb failed")
	if not fail.is_empty():
		push_error("GODOT TESTS FAIL\n" + "\n".join(fail))
		quit(1)
		return
	print("godot tests ok")
	quit(0)
