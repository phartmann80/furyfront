class_name WeaponDefinition
extends Resource
## Populated from data/weapons.json. Do not enter balance numbers in scenes.

@export var id: String
@export var display_name: String
@export var weapon_class: String
@export var damage_max: float
@export var damage_min: float
@export var head_multiplier: float
@export var limb_multiplier: float
@export var rpm: float
@export var magazine_size: int
@export var reserve_ammo: int
@export var reload_ms: int
@export var ads_ms: int
@export var sprint_out_ms: int
@export var movement_modifier: float
@export var penetration: String = "none"

static func from_dict(d: Dictionary) -> WeaponDefinition:
	var w := WeaponDefinition.new()
	w.id = str(d.get("id", ""))
	w.display_name = str(d.get("name", ""))
	w.weapon_class = str(d.get("class", ""))
	w.damage_max = float(d.get("damageMax", 0))
	w.damage_min = float(d.get("damageMin", 0))
	w.head_multiplier = float(d.get("head", 1))
	w.limb_multiplier = float(d.get("limb", 1))
	w.rpm = float(d.get("rpm", 0))
	w.magazine_size = int(d.get("mag", 0))
	w.reserve_ammo = int(d.get("reserves", 0))
	w.reload_ms = int(d.get("reloadMs", 0))
	w.ads_ms = int(d.get("adsMs", 0))
	w.sprint_out_ms = int(d.get("sprintOutMs", 0))
	w.movement_modifier = float(d.get("move", 1))
	w.penetration = str(d.get("penetration", "none"))
	return w
