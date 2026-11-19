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
