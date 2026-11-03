# Level01.gd
# Greybox Level 1 — Room 1A (Reality A) + Room 1B (Reality B)
# S1-05: Level 1 Design §3–4; Arsitektur §2, §11.1
# Hanya greybox + kamera fixed. Tanpa Plate, Door, Link.

extends Node2D

func _ready() -> void:
    # Wiring @export references untuk RealityManager, CameraDirector, UIDirector
    var reality_manager := get_node("RealityManager")
    reality_manager.character_a = get_node("CharacterA")
    reality_manager.character_b = get_node("CharacterB")
    reality_manager.camera_a = get_node("RealityA/CameraA")
    reality_manager.camera_b = get_node("RealityB/CameraB")

    var camera_director := get_node("CameraDirector")
    camera_director.pip_camera = get_node("UI/PiPViewport/SubViewport/PiPCamera")
    camera_director.camera_a = get_node("RealityA/CameraA")
    camera_director.camera_b = get_node("RealityB/CameraB")

    var ui_director := get_node("UIDirector")
    ui_director.reality_label = get_node("UI/RealityIndicator")
    ui_director.cooldown_bar = get_node("UI/SwitchCooldownBar")
    ui_director.reality_a_root = get_node("RealityA")
    ui_director.reality_b_root = get_node("RealityB")
    ui_director.reality_manager = reality_manager
