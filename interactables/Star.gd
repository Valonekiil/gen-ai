extends Area2D

# Bintang koleksi. Hanya aktif (monitoring) saat realitas-nya sedang aktif.
@export var reality: String = "A"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = reality == "A"
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.character_switched.connect(_on_character_switched)

func _on_character_switched(new_active: String, _previous: String) -> void:
	# Deferred: sinyal bisa keluar saat physics flush
	set_deferred("monitoring", new_active == reality)

func _on_body_entered(body: Node2D) -> void:
	if not monitoring:
		return
	if body is CharacterController:
		set_deferred("monitoring", false)
		var sb := get_node_or_null("/root/SignalBus")
		if sb:
			sb.star_collected.emit()
		queue_free()