# AudioManager.gd
# Autoload: BGM (crossfade) + SFX pool.
# Bus BGM  : Music_Menu / Music_RealityA / Music_RealityB
# Bus SFX  : pool efek + DialogLoop
extends Node

const BGM_MENU := "res://assets/audio/MainMenuBGM.mp3"
const BGM_A := "res://assets/audio/RealityABGM.mp3"
const BGM_B := "res://assets/audio/RealityBBGM.mp3"

const SFX := {
	"UIClick": "res://assets/audio/UIClick.wav",
	"UIDialogue": "res://assets/audio/UIDialogue.wav",
	"UIDoor": "res://assets/audio/UIDoor.wav",
	"UILevelCompleted": "res://assets/audio/UILevelCompleted.wav",
	"UIRealitySwitch": "res://assets/audio/UIRealitySwitch.wav",
	"UIResonance": "res://assets/audio/UIResonance.wav",
	"UISwitch": "res://assets/audio/UISwitch.wav",
}

const FADE_DURATION := 0.8

var _music_menu: AudioStreamPlayer
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _dialog_player: AudioStreamPlayer = null
var _fade_index: int = 0

func _ready() -> void:
	_music_menu = _make_player(BGM_MENU, "BGM", "Music_Menu")
	_music_a = _make_player(BGM_A, "BGM", "Music_RealityA")
	_music_b = _make_player(BGM_B, "BGM", "Music_RealityB")

	# Pool SFX di bus SFX
	for i in range(16):
		var p := AudioStreamPlayer.new()
		p.name = "Sfx_%02d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	# Player khusus dialog (loop) di bus SFX
	_dialog_player = AudioStreamPlayer.new()
	_dialog_player.name = "DialogLoop"
	_dialog_player.bus = "SFX"
	var ds: AudioStream = load(SFX["UIDialogue"])
	if ds is AudioStreamWAV:
		ds.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_dialog_player.stream = ds
	add_child(_dialog_player)

func _make_player(path: String, bus: String, pname: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = pname
	p.stream = load(path)
	p.bus = bus
	p.volume_db = 0.0
	add_child(p)
	return p

# --- BGM: crossfade ---

func play_menu_bgm() -> void:
	_crossfade(_music_menu)

func play_reality_bgm(active: String) -> void:
	_crossfade(_music_a if active == "A" else _music_b)

func _crossfade(next: AudioStreamPlayer) -> void:
	if next == null or next == _current_music:
		return
	var old := _current_music
	# Hentikan player lain yang masih hidup dari crossfade yang terputus
	for p in [_music_menu, _music_a, _music_b]:
		if p != next and p != old and p.playing:
			p.stop()
	_current_music = next
	var token := _fade_index + 1
	_fade_index = token

	next.volume_db = -40.0
	if not next.playing:
		next.play()

	var tween := create_tween().set_parallel(true)
	if old and old.playing:
		tween.tween_property(old, "volume_db", -40.0, FADE_DURATION)
	tween.tween_property(next, "volume_db", 0.0, FADE_DURATION)
	await tween.finished
	# Jangan matikan player lama kalau sudah ada crossfade lebih baru yang
	# menjadikannya lagu aktif lagi.
	if old and old != _current_music and token == _fade_index and old.playing:
		old.stop()

# --- SFX ---

func play_sfx(name: String) -> void:
	var path: String = SFX.get(name, "")
	if path == "":
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return

# Dialog: loop selama teks diketik, stop saat selesai
func start_dialog_sfx() -> void:
	if _dialog_player and not _dialog_player.playing:
		_dialog_player.play()

func stop_dialog_sfx() -> void:
	if _dialog_player and _dialog_player.playing:
		_dialog_player.stop()

func _exit_tree() -> void:
	for p in [_music_menu, _music_a, _music_b]:
		if p:
			p.stop()
			p.stream = null
	for p in _sfx_pool:
		p.stop()
		p.stream = null
	if _dialog_player:
		_dialog_player.stop()
		_dialog_player.stream = null
