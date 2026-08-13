class_name HealthComponent
extends Node

signal changed(health: int, armor: int)
signal died

@export var max_health: int = 100
@export var health: int = 100
@export var armor: int = 0
@export var team: String = "shadowbreakers"

var dead: bool = false


func setup(h: int, a: int, t: String) -> void:
	max_health = h
	health = h
	armor = a
	team = t
	dead = false
	changed.emit(health, armor)


func apply_damage(amount: float) -> Dictionary:
	if dead:
		return { "applied": 0, "killed": false, "to_armor": 0, "to_health": 0 }
	var remaining := amount
	var to_armor := 0.0
	if armor > 0:
		to_armor = minf(remaining, float(armor))
		armor = int(round(float(armor) - to_armor))
		remaining -= to_armor
	var to_health := remaining
	health = int(maxi(0, health - int(round(to_health))))
	changed.emit(health, armor)
	var killed := false
	if health <= 0:
		dead = true
		killed = true
		died.emit()
	return {
		"applied": amount - remaining + to_health,
		"killed": killed,
		"to_armor": to_armor,
		"to_health": to_health,
	}
