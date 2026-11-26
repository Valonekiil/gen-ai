# Settings.gd
# Autoload: pengaturan volume (bus BGM & SFX) + fullscreen.
# Tersimpan di user://splitbound_settings.save.
extends Node

const SETTINGS_PATH := "user://splitbound_settings.save"

var music_volume: float = 1.0   # slider "Music" -> bus BGM
var sfx_volume: float = 1.0     # slider "Sfx"  -> bus SFX
var fullscreen: bool = false

func _ready() -> void:
	_ensure_bus("BGM")
	_ensure_bus("SFX")
	load_settings()
	apply()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus("BGM", music_volume)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus("SFX", sfx_volume)
	save_settings()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()

func apply() -> void:
	_apply_bus("BGM", music_volume)
	_apply_bus("SFX", sfx_volume)
	_apply_fullscreen()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func _apply_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	AudioServer.set_bus_mute(idx, value <= 0.0001)

func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = float(cfg.get_value("settings", "music_volume", 1.0))
	sfx_volume = float(cfg.get_value("settings", "sfx_volume", 1.0))
	fullscreen = bool(cfg.get_value("settings", "fullscreen", false))
