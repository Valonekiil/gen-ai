# Door.gd
# Pintu yang bisa dibuka (sprite + collision) (Splitbound)
extends Node2D

class_name Door

var _close_sprite: Sprite2D
var _open_sprite: Sprite2D
var _collision_shape: CollisionShape2D
var is_open: bool = false

func _ready() -> void:
    _close_sprite = get_node_or_null("Close") as Sprite2D
    _open_sprite = get_node_or_null("Open") as Sprite2D
    var static_body := get_node_or_null("Close/StaticBody2D") as StaticBody2D
    if static_body:
        _collision_shape = static_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if _open_sprite:
        _open_sprite.visible = false
    if _close_sprite:
        _close_sprite.visible = true

func open_door() -> void:
    if is_open:
        return
    is_open = true
    if _close_sprite:
        _close_sprite.visible = false
    if _open_sprite:
        _open_sprite.visible = true
    if _collision_shape:
        _collision_shape.disabled = true
    print("[Door] Terbuka")

func close_door() -> void:
    if not is_open:
        return
    is_open = false
    if _close_sprite:
        _close_sprite.visible = true
    if _open_sprite:
        _open_sprite.visible = false
    if _collision_shape:
        _collision_shape.disabled = false
    print("[Door] Tertutup")
