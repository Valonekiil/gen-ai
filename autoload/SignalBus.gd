# SignalBus.gd
# Autoload: SignalBus
# Bus sinyal global untuk komunikasi antar node (decoupling).
# Tidak menyimpan state level atau game.
#
# Splitbound — top-down puzzle | Godot 4.x
# S1-01: script kosong, hanya header comment. Tanpa logika.
# Sinyal dideklarasikan pada tahap lanjutan (S1-02).

extends Node

signal character_switched(new_active: String, previous_active: String)
signal character_facing_changed(reality: String, direction: int)
# Emitted when the player touches a visible Hazard/Spike.
# The handler decides what happens next (damage, restart, etc.).
signal hazard_entered
# Bintang koleksi berhasil diambil player
signal star_collected
# Level selesai: (level_id, jumlah bintang 0-3)
signal level_completed(level_id: String, stars: int)

# Urutan level siklik (dipakai LvlTest dan LevelComplete)
const LEVEL_SEQUENCE := [
	"res://levels/Lvl_0.tscn",
	"res://levels/Lvl_1.tscn",
	"res://levels/Lvl_2.tscn",
	"res://levels/Lvl_3.tscn",
	"res://levels/Lvl_4.tscn",
	"res://levels/Lvl_5.tscn",
]

# Hasil level terakhir, dibaca scene LevelComplete (reusable untuk semua level)
var last_completed_level: String = ""
var last_completed_stars: int = 0
var last_completed_time: float = 0.0

static func next_level_path(from_level: String) -> String:
	var idx := LEVEL_SEQUENCE.find(from_level)
	if idx == -1:
		return LEVEL_SEQUENCE[0]
	return LEVEL_SEQUENCE[(idx + 1) % LEVEL_SEQUENCE.size()]
