extends Node

enum Tier { HIGH, MEDIUM, LOW }

var tier: Tier = Tier.MEDIUM
var particle_scale: float = 1.0
var shadow_enabled: bool = true
var decal_enabled: bool = true
var scaling_3d: float = 1.0
var particle_cap: int = 400
var max_local_lights: int = 4

func _ready() -> void:
	if OS.has_feature("web"):
		tier = Tier.MEDIUM
	elif OS.has_feature("mobile"):
		tier = Tier.LOW
	else:
		tier = Tier.HIGH
	apply()


func set_named(name: String) -> void:
	match name:
		"high":
			tier = Tier.HIGH
		"low":
			tier = Tier.LOW
		_:
			tier = Tier.MEDIUM
	apply()


func apply() -> void:
	match tier:
		Tier.HIGH:
			particle_scale = 1.0
			shadow_enabled = true
			decal_enabled = true
			scaling_3d = 1.0
			particle_cap = 800
			max_local_lights = 6
			Engine.max_fps = 60
		Tier.MEDIUM:
			particle_scale = 0.65
			shadow_enabled = true
			decal_enabled = true
			scaling_3d = 0.85
			particle_cap = 400
			max_local_lights = 4
			Engine.max_fps = 60
		Tier.LOW:
			particle_scale = 0.35
			shadow_enabled = false
			decal_enabled = false
			scaling_3d = 0.7
			particle_cap = 80
			max_local_lights = 2
			Engine.max_fps = 60
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = scaling_3d
	print("GraphicsProfile tier=", tier, " scale=", scaling_3d, " web=", OS.has_feature("web"))
