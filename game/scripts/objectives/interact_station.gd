extends StaticBody3D

signal used(id: String)

@export var hold_s: float = 2.4
var _holding := 0.0
var _busy := false

func _ready() -> void:
	add_to_group("interact")
	set_process(false)
	var catalog_hold := float(ContentCatalog.mission.get("restoreHoldS", hold_s))
	if catalog_hold > 0.0:
		hold_s = catalog_hold


func interact(_player: Node) -> void:
	if _busy:
		return
	set_process(true)


func _process(delta: float) -> void:
	if not Input.is_action_pressed("interact"):
		_holding = 0.0
		set_process(false)
		return
	_holding += delta
	var pct := int((_holding / maxf(hold_s, 0.01)) * 100.0)
	EventBus.notify.emit("%s %d%%" % [str(get_meta("interact", "HOLD")), mini(pct, 99)])
	if _holding >= hold_s:
		_busy = true
		set_process(false)
		used.emit(name)
		EventBus.notify.emit("SECURITY GRID ONLINE")
