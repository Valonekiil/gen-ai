# InteractableBase.gd
# Base class untuk semua interactable (Splitbound)
# S2-01: Mekanik v2.0 §3.2; Arsitektur §4

class_name InteractableBase
extends Node2D

# Token link dari level designer
var link_id: String = ""

# State plate/door
var pressed: bool = false

func interact() -> void:
	# Default: cek karakter di atas tile
	var character_controllers = get_tree().get_nodes_in_group("character_controller")
	for cc in character_controllers:
		var global_pos = cc.global_position
		var local_pos = to_local(global_pos)
		# Check jika di dalam bounding box sederhana (1 tile = 32px)
		if abs(local_pos.x) < 32 and abs(local_pos.y) < 32:
			_pressed_toggled()

func _pressed_toggled() -> void:
	pressed = not pressed
	_emit_link_request()

func _emit_link_request() -> void:
	if link_id == "":
		return
	# Emit ke LinkResolver melalui signal atau direct call
	# Di sini hanya merekod state change
	pass

func on_link_received(link: Dictionary, new_state: bool) -> bool:
	# Default: terima semua link
	pressed = new_state
	return true
