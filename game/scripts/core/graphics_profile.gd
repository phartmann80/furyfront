extends Node

enum Tier { ULTRA, HIGH, MEDIUM, LOW }

var tier: Tier = Tier.HIGH
var particle_scale: float = 1.0
var shadow_enabled: bool = true
var decal_enabled: bool = true

func _ready() -> void:
	_detect()
	apply()


func _detect() -> void:
	if OS.has_feature("web"):
		tier = Tier.MEDIUM
		return
	if OS.has_feature("mobile"):
		var info: Dictionary = OS.get_memory_info()
		var ram_mb: float = float(info.get("physical", 0)) / (1024.0 * 1024.0)
		if ram_mb >= 8000:
			tier = Tier.HIGH
		elif ram_mb >= 4000:
			tier = Tier.MEDIUM
		else:
			tier = Tier.LOW
	else:
		tier = Tier.HIGH
	if DisplayServer.screen_get_refresh_rate() >= 110.0 and not OS.has_feature("mobile"):
		tier = Tier.ULTRA


func apply() -> void:
	match tier:
		Tier.ULTRA:
			particle_scale = 1.25
			shadow_enabled = true
			decal_enabled = true
			Engine.max_fps = 0
		Tier.HIGH:
			particle_scale = 1.0
			shadow_enabled = true
			decal_enabled = true
			Engine.max_fps = 60
		Tier.MEDIUM:
			particle_scale = 0.65
			shadow_enabled = true
			decal_enabled = true
			Engine.max_fps = 60
		Tier.LOW:
			particle_scale = 0.35
			shadow_enabled = false
			decal_enabled = false
			Engine.max_fps = 30
	print("GraphicsProfile tier=", tier, " fps_cap=", Engine.max_fps)
