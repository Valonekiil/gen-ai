# Paused.gd
# Menu jeda. Dipanggil saat pemain menekan P atau tombol Pause.
extends Control

func _ready() -> void:
	# Tree sedang di-pause, node ini tetap harus bisa diproses
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Container/Continue.pressed.connect(_on_continue)
	$Container/Retry.pressed.connect(_on_retry)
	$Container/LevelSelection.pressed.connect(_on_level_selection)

func _input(event: InputEvent) -> void:
	# P untuk menutup menu jeda
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		get_viewport().set_input_as_handled()
		_resume()

func _resume() -> void:
	get_tree().paused = false
	queue_free()

func _on_continue() -> void:
	_resume()

func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_level_selection() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
