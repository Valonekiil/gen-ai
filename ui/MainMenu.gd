# MainMenu.gd
# Menu utama: tombol Play membuka panel Level Selection,
# tombol Setting membuka panel Settings (volume + reset data).
extends Control

const LVL_BUTTON := "res://ui/LvLButton.tscn"

@onready var level_selection: Control = $LevelSelection
@onready var grid: GridContainer = $LevelSelection/TextureRect/GridContainer
@onready var play_btn: TextureButton = $VBoxContainer/PlayBtn
@onready var setting_btn: TextureButton = $VBoxContainer/SettingBtn
@onready var settings_panel: Control = $Settings
@onready var music_slider: HSlider = $Settings/Container1/HSlider
@onready var sfx_slider: HSlider = $Settings/Container2/HSlider
@onready var reset_btn: TextureButton = $Settings/Container3/TextureButton

func _ready() -> void:
	# Panel level selection & settings disembunyikan dulu
	level_selection.visible = false
	settings_panel.visible = false
	play_btn.pressed.connect(_on_play)
	setting_btn.pressed.connect(_on_setting)

	# Slider volume: 0..1, diisi dari Settings lalu disambungkan
	for s in [music_slider, sfx_slider]:
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	reset_btn.pressed.connect(_on_reset_data)
	_build_level_grid()

func _on_play() -> void:
	level_selection.visible = true
	settings_panel.visible = false

func _on_setting() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		level_selection.visible = false

func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value)

func _on_reset_data() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Hapus semua progres level?"
	add_child(dlg)
	dlg.confirmed.connect(_do_reset)
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)
	dlg.popup_centered()

func _do_reset() -> void:
	GameProgress.reset_all()
	_build_level_grid()

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
