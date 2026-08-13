extends StaticBody3D

signal used(id: String)

@export var hold_s: float = 3.5
var _holding := 0.0
var _busy := false

func _ready() -> void:
	add_to_group("interact")
	set_process(false)


func interact(_player: Node) -> void:
	if _busy:
		return
	set_process(true)


func _process(delta: float) -> void:
	if not Input.is_action_pressed("interact") and not InputService.fire_held:
		_holding = 0.0
		set_process(false)
		return
	if not Input.is_action_pressed("interact"):
		# still allow hold from... actually interact is E / HUD button
		pass
	_holding += delta
	EventBus.notify.emit("RESTORING %d%%" % int(_holding / hold_s * 100.0))
	if _holding >= hold_s:
		_busy = true
		set_process(false)
		used.emit(name)
		EventBus.notify.emit("SECURITY GRID ONLINE")
