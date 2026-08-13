extends Node

signal player_damaged(current: int, armor: int)
signal player_died
signal enemy_killed(archetype_id: String)
signal hit_confirmed(headshot: bool, killed: bool)
signal objective_changed(text: String)
signal integrity_changed(value: float)
signal transfer_changed(value: float)
signal alarm_started
signal interact_available(label: String)
signal mission_phase(phase: String)
signal mission_ended(success: bool)
signal weapon_changed(weapon_id: String)
signal ammo_changed(mag: int, reserve: int)
signal notify(text: String)
