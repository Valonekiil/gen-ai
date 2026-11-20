# MainMenu.gd
# Menu utama: tombol Play membuka panel Level Selection.
extends Control

const LVL_BUTTON := "res://ui/LvLButton.tscn"

@onready var level_selection: Control = $LevelSelection
@onready var grid: GridContainer = $LevelSelection/TextureRect/GridContainer
@onready var play_btn: TextureButton = $VBoxContainer/PlayBtn

func _ready() -> void:
	# Panel level selection disembunyikan dulu, muncul setelah Play ditekan
	level_selection.visible = false
	play_btn.pressed.connect(_on_play)
	_build_level_grid()

func _on_play() -> void:
	level_selection.visible = true

# Satu LvLButton per level; level terkunci otomatis disabled + label tersembunyi
func _build_level_grid() -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	for i in SignalBus.LEVEL_SEQUENCE.size():
		var b := load(LVL_BUTTON).instantiate() as TextureButton
		b.level_index = i
		b.level_path = SignalBus.LEVEL_SEQUENCE[i]
		b.level_label = str(i + 1)
		grid.add_child(b)
