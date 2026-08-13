extends Node

const PlayerFactoryScript = preload("res://scripts/player/player_factory.gd")
const IronfallBuilderScript = preload("res://scripts/maps/ironfall_builder.gd")

var world: Node3D
var cinematic: Label

func _ready() -> void:
	world = Node3D.new()
	world.name = "IronfallDepot"
	add_child(world)
	var builder: IronfallBuilder = IronfallBuilderScript.new()
	builder.build(world)
	var spawn: Transform3D = builder.markers.get("staging", Transform3D.IDENTITY)
	PlayerFactoryScript.spawn(self, spawn)
	_allies(spawn.origin)
	var hud := GameplayHud.new()
	add_child(hud)
	var touch := TouchControls.new()
	add_child(touch)
	if OS.has_feature("mobile"):
		touch.visible = true
	else:
		touch.visible = true # layout present for device testing; mouse still works
	var mission := MissionDirector.new()
	add_child(mission)
	_cinematic_overlay()
	mission.start(world, builder.markers)
	AudioDirector.radio("FURY FRONT ACTUAL: Ironfall, hold the depot.")
	print("Fury Front V0.1 boot  renderer=", ProjectSettings.get_setting("rendering/renderer/rendering_method"))


func _allies(origin: Vector3) -> void:
	for i in 3:
		var a := AllySoldier.new()
		add_child(a)
		a.setup(origin + Vector3(-2.0 + i * 2.0, 0, 1.5))


func _cinematic_overlay() -> void:
	cinematic = Label.new()
	cinematic.position = Vector2(480, 420)
	cinematic.size = Vector2(960, 200)
	cinematic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cinematic.add_theme_font_size_override("font_size", 28)
	cinematic.add_theme_color_override("font_color", Color(0.91, 0.64, 0.09))
	add_child(cinematic)
	_cine_seq()


func _cine_seq() -> void:
	var lines := [
		"IRONFALL DEPOT — 04:12 LOCAL",
		"Routine patrol. Comms check.",
		"Interference detected…",
		"Cameras offline. Perimeter sensors dark.",
		"SHADOWBREAKER BREACH",
		"ALARM. All Fury Front elements — defend the command center.",
	]
	for line in lines:
		cinematic.text = line
		await get_tree().create_timer(3.4).timeout
	cinematic.visible = false
