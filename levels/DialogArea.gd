# DialogArea.gd
# Area pemicu dialog: saat pemain masuk, dialog tampil di gelembung karakter.
extends Area2D

@export var dialog_text: String = ""
@export var chars_per_second: float = 40.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterController:
		return
	# Hanya picu bila realita tempat area ini berada sedang aktif
	if not is_visible_in_tree():
		return
	var lvl := owner
	if lvl and lvl.has_method("start_dialog"):
		lvl.start_dialog(dialog_text, chars_per_second)
