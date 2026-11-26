# GameProgress.gd
# Autoload: progres pembukaan level + bintang per level (persisten di user://).
extends Node

const SAVE_PATH := "user://splitbound_progress.save"

# Index level tertinggi yang sudah terbuka (level 0 selalu terbuka)
var max_unlocked: int = 0
# level_path -> jumlah bintang terbaik (0..3)
var level_stars: Dictionary = {}

func _ready() -> void:
	load_progress()

func is_unlocked(index: int) -> bool:
	return index <= max_unlocked

func stars_for(level_path: String) -> int:
	return int(level_stars.get(level_path, 0))

# Hapus progres satu level (bintang yang sudah diraih)
func reset_level(level_path: String) -> void:
	level_stars.erase(level_path)
	save_progress()

# Hapus progres semua level: bintang dibersihkan dan level terkunci lagi
# kecuali level pertama.
func reset_all() -> void:
	level_stars.clear()
	max_unlocked = 0
	save_progress()

# Dipanggil saat level selesai: membuka level berikutnya + simpan bintang terbaik
func record_completion(level_path: String, stars_earned: int) -> void:
	var idx := SignalBus.LEVEL_SEQUENCE.find(level_path)
	if idx == -1:
		return
	# Jangan sampai melewati index level terakhir yang ada
	max_unlocked = maxi(max_unlocked, mini(idx + 1, SignalBus.LEVEL_SEQUENCE.size() - 1))
	level_stars[level_path] = maxi(stars_for(level_path), stars_earned)
	save_progress()

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "max_unlocked", max_unlocked)
	cfg.set_value("progress", "stars", level_stars)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	max_unlocked = int(cfg.get_value("progress", "max_unlocked", 0))
	var s: Dictionary = cfg.get_value("progress", "stars", {})
	level_stars = s
