class_name GameplayHud
extends CanvasLayer

var hp: Label
var ammo: Label
var obj: Label
var alert: Label
var integrity: Label
var transfer: Label
var extract: Label
var interact: Label
var cross: ColorRect
var hit: ColorRect
var fps: Label

func _ready() -> void:
	layer = 10
	_build()
	EventBus.player_damaged.connect(_on_hp)
	EventBus.ammo_changed.connect(_on_ammo)
	EventBus.objective_changed.connect(func(t: String) -> void: obj.text = t)
	EventBus.integrity_changed.connect(func(v: float) -> void: integrity.text = "Security Integrity: %d%%" % int(v))
	EventBus.transfer_changed.connect(func(v: float) -> void: transfer.text = "Enemy Data Transfer: %d%%" % int(v))
	EventBus.hit_confirmed.connect(_hitmarker)
	EventBus.notify.connect(func(t: String) -> void: alert.text = t)
	EventBus.interact_available.connect(func(t: String) -> void: interact.text = ("[E] " + t) if t != "" else "")
	EventBus.weapon_changed.connect(func(id: String) -> void: ammo.text = id)
	EventBus.mission_ended.connect(_results)


func _build() -> void:
	hp = _lab(Vector2(32, 980), "100 HP  |  25 ARMOR")
	ammo = _lab(Vector2(1600, 980), "30 | 120")
	obj = _lab(Vector2(700, 40), "COMMAND CENTER\nDEFEND")
	obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert = _lab(Vector2(700, 120), "SECURITY BREACH")
	alert.add_theme_font_size_override("font_size", 22)
	integrity = _lab(Vector2(32, 40), "Security Integrity: 100%")
	transfer = _lab(Vector2(32, 72), "Enemy Data Transfer: 0%")
	extract = _lab(Vector2(32, 104), "Extraction: LOCKED")
	interact = _lab(Vector2(800, 820), "")
	cross = ColorRect.new()
	cross.size = Vector2(8, 8)
	cross.position = Vector2(956, 536)
	cross.color = Color(1, 1, 1, 0.75)
	add_child(cross)
	hit = ColorRect.new()
	hit.size = Vector2(14, 14)
	hit.position = Vector2(953, 533)
	hit.color = Color(1, 1, 1, 0)
	add_child(hit)
	_lab(Vector2(32, 140), "SQUAD  VEX · FF-02 · FF-03 · FF-04")
	fps = _lab(Vector2(1720, 40), "FPS --")


func _process(_delta: float) -> void:
	if fps:
		fps.text = "FPS %d" % int(Engine.get_frames_per_second())


func _lab(pos: Vector2, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", Color(0.9, 0.91, 0.92))
	l.add_theme_font_size_override("font_size", 16)
	add_child(l)
	return l


func _on_hp(h: int, a: int) -> void:
	hp.text = "%d HP  |  %d ARMOR" % [h, a]


func _on_ammo(mag: int, res: int) -> void:
	ammo.text = "%d | %d" % [mag, res]


func _hitmarker(head: bool, killed: bool) -> void:
	hit.color = Color(1, 0.75, 0.15, 1) if head else Color(1, 1, 1, 1)
	if killed:
		hit.color = Color(0.85, 0.15, 0.12, 1)
	await get_tree().create_timer(0.08).timeout
	hit.color.a = 0


func _results(ok: bool) -> void:
	obj.text = "MISSION SUCCESS" if ok else "MISSION FAILED"
	extract.text = "Extraction: DENIED" if ok else "Extraction: LOST"
