extends Node

var health: int = 100
var armor: int = 25
var max_health: int = 100
var spawn_xform: Transform3D
var mission_success: bool = false
var debug_invuln: bool = false
## Mode-scoped armor. V0.1 uses plate absorb. Recon Protocol / BR must not reuse this blindly.
var armor_model: String = "mp_plates_v01"

func reset_combat() -> void:
	max_health = int(ContentCatalog.balance.get("healthBase", 100))
	health = max_health
	armor = int(ContentCatalog.balance.get("armor", {}).get("prototypePlates", 25))
