# LvLButton.gd
# Tombol level di scene Level Selection: label nomor level + bintang.
# Level yang belum terbuka: tombol disabled dan label disembunyikan.
extends TextureButton

const STAR_FILLED := "res://Assets/UI/Component/GStar.png"
const STAR_EMPTY := "res://Assets/UI/Component/PStar.png"

@export var level_index: int = 0
@export var level_path: String = ""
@export var level_label: String = "1"

@onready var label: Label = $Label
@onready var stars_row: HBoxContainer = $Control/HBoxContainer

func _ready() -> void:
	configure()
	pressed.connect(_on_pressed)

func configure() -> void:
	label.text = level_label
	var unlocked := GameProgress.is_unlocked(level_index)
	disabled = not unlocked
	label.visible = unlocked
	if unlocked:
		var filled: Texture2D = load(STAR_FILLED)
		var empty: Texture2D = load(STAR_EMPTY)
		var s := GameProgress.stars_for(level_path)
		for i in stars_row.get_child_count():
			var tr := stars_row.get_child(i) as TextureRect
			if tr:
				tr.texture = filled if i < s else empty

func _on_pressed() -> void:
	if disabled:
		return
	get_tree().change_scene_to_file(level_path)
