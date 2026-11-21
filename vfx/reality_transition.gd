class_name RealityTransition
extends CanvasLayer
## VFX transisi antar realitas. Dibuat penuh lewat kode, tidak perlu setup scene.
## Membutuhkan res://vfx/reality_transition.gdshader

signal covered   # layar tertutup penuh -> aman untuk menukar realitas
signal finished  # efek selesai sepenuhnya

const SHADER := preload("res://vfx/reality_transition.gdshader")

@export var in_duration: float = 0.5
@export var out_duration: float = 0.7
# Warna transisi: biru muda saat menuju realita B, oranye saat menuju realita A
@export var tint_to_b: Color = Color(0.50, 0.82, 1.0)
@export var glow_to_b: Color = Color(0.88, 0.97, 1.0)
@export var tint_to_a: Color = Color(1.0, 0.60, 0.20)
@export var glow_to_a: Color = Color(1.0, 0.90, 0.72)

var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 100
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_apply_colors("B")

	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	add_child(_rect)


func _set_intensity(v: float) -> void:
	_mat.set_shader_parameter("intensity", v)


func _apply_colors(to_reality: String) -> void:
	if to_reality == "A":
		_mat.set_shader_parameter("tint_color", tint_to_a)
		_mat.set_shader_parameter("glow_color", glow_to_a)
	else:
		_mat.set_shader_parameter("tint_color", tint_to_b)
		_mat.set_shader_parameter("glow_color", glow_to_b)


## center: posisi pemain dalam UV layar (0..1), titik awal ring.
## to_reality: "A" (oranye) atau "B" (biru muda).
func play_in(center: Vector2 = Vector2(0.5, 0.5), to_reality: String = "B") -> void:
	_apply_colors(to_reality)
	_mat.set_shader_parameter("center", center)
	_set_intensity(0.0)
	_rect.visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_intensity, 0.0, 1.0, in_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await _tween.finished
	covered.emit()


## center: posisi pemain di realita tujuan (UV layar 0..1); ring menyusut ke titik ini.
func play_out(center: Vector2 = Vector2(0.5, 0.5)) -> void:
	_mat.set_shader_parameter("center", center)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_intensity, 1.0, 0.0, out_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _tween.finished
	_rect.visible = false
	finished.emit()
