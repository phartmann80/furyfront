extends Node

var weapons: Dictionary = {}
var operators: Dictionary = {}
var enemies: Dictionary = {}
var skill_profiles: Dictionary = {}
var maps: Dictionary = {}
var modes: Dictionary = {}
var mission: Dictionary = {}
var factions: Dictionary = {}
var balance: Dictionary = {}

func _ready() -> void:
	weapons = _index(_load("weapons.json").get("weapons", []), "id")
	operators = _index(_load("operators.json").get("operators", []), "id")
	var ed: Dictionary = _load("enemies.json")
	enemies = _index(ed.get("archetypes", []), "id")
	skill_profiles = ed.get("skillProfiles", {})
	maps = _index(_load("maps.json").get("maps", []), "id")
	modes = _index(_load("modes.json").get("modes", []), "id")
	mission = _load("missions.json")
	factions = _load("factions.json")
	balance = _load("balance.json")
	assert(factions.get("enemy", {}).get("id", "") == "faction_shadowbreakers")


func get_weapon(id: String) -> Dictionary:
	return weapons.get(id, {})


func _load(name: String) -> Dictionary:
	var path := "res://resources/balance/%s" % name
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ContentCatalog missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ContentCatalog invalid JSON %s" % path)
		return {}
	return parsed


func _index(arr: Array, key: String) -> Dictionary:
	var out := {}
	for item in arr:
		if typeof(item) == TYPE_DICTIONARY and item.has(key):
			out[item[key]] = item
	return out
