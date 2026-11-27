# MainMenu.gd
# Menu utama: Play -> Level Selection, Setting -> panel Settings, power -> quit.
extends Control

const LVL_BUTTON := "res://ui/LvLButton.tscn"

@onready var level_selection: Control = $LevelSelection
@onready var grid: GridContainer = $LevelSelection/TextureRect/GridContainer
@onready var play_btn: TextureButton = $VBoxContainer/PlayBtn
@onready var setting_btn: TextureButton = $VBoxContainer/SettingBtn
@onready var quit_btn: TextureButton = $VBoxContainer/TextureButton
@onready var settings_panel: Control = $Settings
@onready var music_slider: HSlider = $Settings/Container1/SliderWrap/HSlider
@onready var sfx_slider: HSlider = $Settings/Container2/SliderWrap/HSlider
@onready var fullscreen_toggle: TextureButton = $Settings/FullscreenToggle
@onready var reset_btn: TextureButton = $Settings/Container3/TextureButton
@onready var settings_back: TextureButton = $Settings/BackBtn
@onready var level_back: TextureButton = $LevelSelection/BackBtn

func _ready() -> void:
	level_selection.visible = false
	settings_panel.visible = false
	play_btn.pressed.connect(_on_play)
	setting_btn.pressed.connect(_on_setting)
	quit_btn.pressed.connect(_on_quit)

	for s in [music_slider, sfx_slider]:
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	fullscreen_toggle.button_pressed = Settings.fullscreen
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	settings_back.pressed.connect(_on_settings_back)
	level_back.pressed.connect(_on_level_back)
	reset_btn.pressed.connect(_on_reset_data)
	_build_level_grid()

	# BGM menu utama
	AudioManager.play_menu_bgm()

func _on_play() -> void:
	AudioManager.play_sfx("UIClick")
	level_selection.visible = true
	settings_panel.visible = false

func _on_setting() -> void:
	AudioManager.play_sfx("UIClick")
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		level_selection.visible = false

func _on_quit() -> void:
	AudioManager.play_sfx("UIClick")
	get_tree().quit()

func _on_settings_back() -> void:
	AudioManager.play_sfx("UIClick")
	settings_panel.visible = false

func _on_level_back() -> void:
	AudioManager.play_sfx("UIClick")
	level_selection.visible = false

func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.set_fullscreen(pressed)
	AudioManager.play_sfx("UISwitch")

func _on_reset_data() -> void:
	# Langsung reset tanpa dialog konfirmasi.
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
