# Settings.gd
# Autoload: pengaturan volume (Music/Sfx) yang dipakai panel Settings di Main Menu.
# Disimpan di user://splitbound_settings.save dan langsung diterapkan ke AudioServer.
extends Node

const SETTINGS_PATH := "user://splitbound_settings.save"

var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("Sfx")
	load_settings()
	apply()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus("Music", music_volume)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus("Sfx", sfx_volume)
	save_settings()

func apply() -> void:
	_apply_bus("Music", music_volume)
	_apply_bus("Sfx", sfx_volume)

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

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = float(cfg.get_value("settings", "music_volume", 1.0))
	sfx_volume = float(cfg.get_value("settings", "sfx_volume", 1.0))
