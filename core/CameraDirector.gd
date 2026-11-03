# CameraDirector.gd
# class_name CameraDirector — swap active camera, mirror PiP camera (Splitbound)
# S1-06: Arsitektur §11.2; Mekanik v2.0 §2.5

class_name CameraDirector
extends Node

@export var pip_camera: Camera2D
@export var camera_a: Camera2D
@export var camera_b: Camera2D

func _ready() -> void:
    SignalBus.character_switched.connect(_on_character_switched)

func _on_character_switched(new_active: String, _previous: String) -> void:
    var inactive_camera: Camera2D = _get_inactive_camera(new_active)

    # Mirror kamera realita inactive ke PiP (bukan follow karakter)
    pip_camera.global_position = inactive_camera.global_position
    pip_camera.limit_left = inactive_camera.limit_left
    pip_camera.limit_right = inactive_camera.limit_right
    pip_camera.limit_top = inactive_camera.limit_top
    pip_camera.limit_bottom = inactive_camera.limit_bottom
    pip_camera.zoom = inactive_camera.zoom
    pip_camera.make_current()  # untuk SubViewport

func _get_inactive_camera(new_active: String) -> Camera2D:
    if new_active == "A":
        return camera_b
    return camera_a
