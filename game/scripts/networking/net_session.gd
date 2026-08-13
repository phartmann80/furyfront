extends Node
## Future dedicated-server boundary. V0.1 is offline; clients must not own damage later.
class_name NetSession

var authoritative: bool = true
var simulated_latency_ms: int = 0

func confirm_hit(_request: Dictionary) -> Dictionary:
	return { "accepted": true }
