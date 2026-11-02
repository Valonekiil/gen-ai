# SignalBus.gd
# Autoload: SignalBus
# Bus sinyal global untuk komunikasi antar node (decoupling).
# Tidak menyimpan state level atau game.
#
# Splitbound — top-down puzzle | Godot 4.x
# S1-01: script kosong, hanya header comment. Tanpa logika.
# Sinyal dideklarasikan pada tahap lanjutan (S1-02).

class_name SignalBus
extends Node

signal character_facing_changed(reality: String, direction: int)
