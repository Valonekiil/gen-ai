# LevelComplete.gd
# Scene reusable untuk semua level: menampilkan hasil (bintang + waktu)
# dan tombol navigasi. Data diambil dari SignalBus (diisi LvlTest saat exit).
extends Control

const STAR_FILLED := "res://Assets/UI/Component/GStar.png"
const STAR_EMPTY := "res://Assets/UI/Component/PStar.png"
const MAIN_MENU := "res://ui/MainMenu.tscn"

@onready var stars_row: HBoxContainer = $Stars
@onready var time_label: Label = $TimeLabel
@onready var title_label: Label = $Title

func _ready() -> void:
	var level_id := SignalBus.last_completed_level
	var stars := SignalBus.last_completed_stars
	var elapsed := SignalBus.last_completed_time

	var filled: Texture2D = load(STAR_FILLED)
	var empty: Texture2D = load(STAR_EMPTY)
	for i in stars_row.get_child_count():
		var tr := stars_row.get_child(i) as TextureRect
		if tr:
			tr.texture = filled if i < stars else empty

	time_label.text = "WAKTU %s" % _format_time(elapsed)

	$Buttons/RetryBtn.pressed.connect(_on_retry)
	$Buttons/NextBtn.pressed.connect(_on_next)
	$Buttons/LevelSelectBtn.pressed.connect(_on_level_select)
	$Buttons/HomeBtn.pressed.connect(_on_home)

func _format_time(t: float) -> String:
	var total := int(max(0.0, t))
	return "%02d:%02d" % [total / 60, total % 60]

func _click() -> void:
	AudioManager.play_sfx("UIClick")

func _on_retry() -> void:
	_click()
	get_tree().change_scene_to_file(SignalBus.last_completed_level)

func _on_next() -> void:
	_click()
	get_tree().change_scene_to_file(SignalBus.next_level_path(SignalBus.last_completed_level))

func _on_home() -> void:
	_click()
	get_tree().change_scene_to_file(MAIN_MENU)

# Belum ada scene pemilih level -> kembali ke menu utama
func _on_level_select() -> void:
	_click()
	get_tree().change_scene_to_file(MAIN_MENU)
