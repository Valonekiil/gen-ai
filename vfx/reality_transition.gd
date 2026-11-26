class_name RealityTransition
extends CanvasLayer
## VFX transisi: pindah realitas (A oranye / B biru muda), spawn, dan kematian (merah).
## Dipasang sebagai autoload "TransitionFX" (lihat project.godot) supaya node ini
## tetap hidup dan tetap menutup layar saat scene di-reload.
## Membutuhkan res://vfx/reality_transition.gdshader

signal covered   # layar tertutup penuh -> aman untuk menukar realitas / reset scene
signal finished  # efek memudar selesai sepenuhnya

const SHADER := preload("res://vfx/reality_transition.gdshader")

@export var in_duration: float = 0.5
@export var out_duration: float = 0.7

# Warna transisi: biru muda saat menuju realita B, oranye saat menuju realita A
@export var tint_to_b: Color = Color(0.50, 0.82, 1.0)
@export var glow_to_b: Color = Color(0.88, 0.97, 1.0)
@export var tint_to_a: Color = Color(1.0, 0.60, 0.20)
@export var glow_to_a: Color = Color(1.0, 0.90, 0.72)
# Warna saat karakter mati (merah)
@export var tint_death: Color = Color(1.0, 0.25, 0.25)
@export var glow_death: Color = Color(1.0, 0.82, 0.78)

var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween
var _intensity: float = 0.0


## Posisi sebuah node 2D di layar dalam UV (0..1), mengikuti kamera aktif.
static func screen_uv(item: CanvasItem) -> Vector2:
	if item == null or not item.is_inside_tree():
		return Vector2(0.5, 0.5)
	var pos := item.get_global_transform_with_canvas().origin
	var uv := pos / item.get_viewport().get_visible_rect().size
	return uv.clamp(Vector2.ZERO, Vector2.ONE)


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
	_intensity = v
	_mat.set_shader_parameter("intensity", v)


## preset: "A" (oranye), "B" (biru muda), atau "DEATH" (merah)
func _apply_colors(preset: String) -> void:
	match preset:
		"A":
			_mat.set_shader_parameter("tint_color", tint_to_a)
			_mat.set_shader_parameter("glow_color", glow_to_a)
		"DEATH":
			_mat.set_shader_parameter("tint_color", tint_death)
			_mat.set_shader_parameter("glow_color", glow_death)
		_:
			_mat.set_shader_parameter("tint_color", tint_to_b)
			_mat.set_shader_parameter("glow_color", glow_to_b)


## Layar ditutup penuh seketika. Jika layar sudah tertutup (mis. setelah
## efek kematian), warna yang sedang tampil dipertahankan agar tidak ada lonjakan warna.
func cover(preset: String = "A") -> void:
	if not _rect.visible:
		_apply_colors(preset)
	if _tween:
		_tween.kill()
	_set_intensity(1.0)
	_rect.visible = true


## center: posisi pemain dalam UV layar (0..1), titik awal ring.
## preset: "A" (oranye), "B" (biru muda), atau "DEATH" (merah).
## Selesai (await) saat layar tertutup penuh.
func play_in(center: Vector2 = Vector2(0.5, 0.5), preset: String = "B") -> void:
	var from := _intensity if _rect.visible else 0.0
	_apply_colors(preset)
	_mat.set_shader_parameter("center", center)
	_set_intensity(from)
	_rect.visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_intensity, from, 1.0, in_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await _tween.finished
	covered.emit()


## center: posisi pemain di realita tujuan (UV layar 0..1); ring menyusut ke titik ini.
func play_out(center: Vector2 = Vector2(0.5, 0.5)) -> void:
	_mat.set_shader_parameter("center", center)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_intensity, _intensity, 0.0, out_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _tween.finished
	_rect.visible = false
	finished.emit()


## Efek spawn di awal level: layar ditutup dulu, lalu ring menyusut ke posisi
## karakter. Dua frame ditunggu agar posisi karakter & kamera sudah stabil
## (layar masih tertutup selama itu).
func play_spawn(character: CanvasItem, preset: String = "A") -> void:
	cover(preset)
	await get_tree().process_frame
	await get_tree().process_frame
	play_out(screen_uv(character))
