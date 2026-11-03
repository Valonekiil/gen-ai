# RealityManager.gd
# class_name RealityManager — state machine switch, cooldown, pause hazard (Splitbound)
# S1-06: Arsitektur §7, §11.2; Mekanik v2.0 §2.5
# Tanpa BossTransition.

class_name RealityManager
extends Node

enum State { RunningA, RunningB, Switching, LevelReset }

const SWITCH_COOLDOWN := 0.25

var state: State = State.RunningA
var _cooldown_timer: float = 0.0

@export var character_a: CharacterController
@export var character_b: CharacterController
@export var camera_a: Camera2D
@export var camera_b: Camera2D

func _process(delta: float) -> void:
    if _cooldown_timer > 0.0:
        _cooldown_timer -= delta

func can_switch() -> bool:
    return _cooldown_timer <= 0.0 and state in [State.RunningA, State.RunningB]

func request_switch() -> void:
    if not can_switch():
        return

    var previous_active: String
    var new_active: String

    if state == State.RunningA:
        previous_active = "A"
        new_active = "B"
    else:
        previous_active = "B"
        new_active = "A"

    state = State.Switching
    _cooldown_timer = SWITCH_COOLDOWN

    # Karakter aktif menjadi inactive
    var active_char := _get_char(previous_active)
    active_char.velocity = Vector2.ZERO
    active_char.set_input_enabled(false)
    active_char.state = CharacterController.State.INACTIVE_FROZEN

    # Karakter inactive menjadi aktif
    var inactive_char := _get_char(new_active)
    inactive_char.set_input_enabled(true)
    inactive_char.state = CharacterController.State.ACTIVE_CONTROLLED

    # Emit sinyal switch (CameraDirector + UIDirector akan dengar)
    SignalBus.character_switched.emit(new_active, previous_active)

    state = State.RunningA if new_active == "A" else State.RunningB

func _get_char(reality: String) -> CharacterController:
    if reality == "A":
        return character_a
    return character_b
