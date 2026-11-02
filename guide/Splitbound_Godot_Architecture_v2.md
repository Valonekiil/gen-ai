# Splitbound — Arsitektur Godot 4 (v2.0 Top-Down)

> **Status:** Draft v2.0
> **Ruang Lingkup:** Arsitektur teknis untuk prototype MVP
> **Target Engine:** Godot 4.3+
> **Perubahan dari v1.0:** Pivot ke top-down — hapus gravity/jump, kamera fixed, 4-directional movement
> **Terkait:** Mekanik Formal v2.0 (Langkah 1), Level 1 Design (Langkah 2), Prototype Backlog (Langkah 5)

---

## 0. Perubahan dari v1.0 & Keputusan Kunci

### 0.1 Perubahan dari v1.0

| Aspek | v1.0 (Platformer) | v2.0 (Top-Down) |
|---|---|---|
| Movement | Horizontal + jump + gravity | **4-directional, tanpa gravity** |
| Jump | `CharacterBody2D` + `jump_velocity` | **Dihapus total** |
| `is_on_floor()` | Wajib | **Tidak dipakai** |
| Camera | Follow player + smoothing | **Fixed per room** |
| PiP | Follow karakter inactive | **Render kamera realita inactive** |
| Perspektif | Side-view | Pure top-down |
| Tileset | Platformer tiles | Top-down tiles |
| Moving platform | Vertikal | Moving surface (4 arah) |
| Push | Horizontal | **4-directional** |
| Hazard | Spike pit + fall | **Spike tile saja** |
| Boss transition | Ada di state machine | Dihapus dari MVP |

### 0.2 Keputusan Arsitektur Kunci

| Keputusan | Pilihan | Alasan |
|---|---|---|
| Rendering realita | Active full-screen + PiP | Fokus visual, PiP jaga awareness |
| Dunia | **Satu World2D**, dua realita di-offset spasial | Sederhana untuk solo dev |
| Posisi realita | Reality A di `(0,0)`, Reality B di `(10000,0)` | Tidak akan collision |
| Kamera aktif | `Camera2D` **fixed** per room | Room kecil & kompleks |
| Kamera PiP | `Camera2D` **fixed** di realita inactive | Cermin kamera aktif |
| Movement | 4-directional (`Vector2i` facing) | Grid-aligned, push simpel |
| Logika puzzle | Grid-based (`Vector2i`) | Deterministik, rollback mudah |
| Karakter | `CharacterBody2D` tanpa gravity | Movement bebas 4-arah |
| Pushable | `AnimatableBody2D` grid-snapped | Rollback mudah |
| Terrain | `TileMapLayer` top-down | Standar Godot 4 |
| Data link | `Resource` (`RealityLink`) | Data-driven |
| Komunikasi | Signal bus (autoload `SignalBus`) | Decoupling |
| State room | Snapshot + reset | Wajib untuk puzzle |

---

## 1. Prinsip Arsitektur

1. **Pisahkan logika dari presentasi.** Validitas puzzle tidak bergantung pada animasi.
2. **Event-driven, bukan polling.** Gunakan signal.
3. **Data-driven.** Link, room config, checkpoint disimpan sebagai `Resource`.
4. **Deterministik.** Grid-based logika memastikan hasil sama di setiap run.
5. **Debuggable.** Setiap perubahan state terlihat di overlay.
6. **Solo-friendly.** Sedikit autoload, sedikit abstraksi, banyak komentar.
7. **No physics drift.** Tidak ada gravity, tidak ada inertia, tidak ada physics push liar.

---

## 2. Scene Tree Global

```text
Main (Node2D)
├── [Autoload: SignalBus, RoomManager, AudioManager, DebugConfig]
├── WorldRoot (Node2D)
│   └── RoomSlot (Node2D)              ← level scene di-instantiate di sini
│       └── Level01 (dari Level01.tscn)
│           ├── RealityA (Node2D, position = (0,0))
│           │   ├── TerrainA (TileMapLayer)        ← top-down tileset
│           │   ├── HazardsA (Node2D)              ← spike, di-pause saat B aktif
│           │   ├── InteractablesA (Node2D)
│           │   │   ├── Plate01 (Plate)
│           │   │   ├── Lever01 (Lever)
│           │   │   ├── Pushable01 (PushableObject)
│           │   │   ├── Door01 (Door)
│           │   │   └── Surface01 (MovingSurface)
│           │   ├── SpawnA (Marker2D)
│           │   ├── SafeAnchorsA (Node2D)
│           │   │   └── Anchor01..N (Marker2D)
│           │   ├── ExitZoneA (Area2D)
│           │   └── CameraA (Camera2D)             ← FIXED, limit = room bounds
│           ├── RealityB (Node2D, position = (10000,0))
│           │   └── [struktur sama dengan RealityA]
│           ├── CharacterA (CharacterBody2D)       ← spawn runtime
│           ├── CharacterB (CharacterBody2D)
│           ├── Links (Node)                       ← array RealityLink resource
│           └── LevelConfig (Resource)
├── PiPViewport (SubViewportContainer, UI, pojok kanan atas)
│   └── SubViewport
│       └── PiPCamera (Camera2D)                   ← FIXED, mirror kamera inactive
├── RealityManager (Node)
├── LinkResolver (Node)
└── UI (CanvasLayer)
	├── RealityIndicator
	├── SwitchCooldownBar
	├── HintPanel
	├── DebugOverlay
	└── PauseMenu
```

**Catatan penting:**

- **`CameraA` dan `CameraB` fixed.** Posisi di-set saat `_ready()` ke center room. Tidak follow karakter. Tidak smoothing.
- **`PiPCamera` mirror kamera realita inactive.** Saat switch, `PiPCamera.global_position` = posisi `CameraA/B` realita inactive. **Tidak follow karakter.**
- **`HazardsA/B`** adalah grup node spike. Saat switch, di-pause via `process_mode`.
- **Tidak ada `Jump` state** di CharacterController.
- **Tidak ada `BossTransition`** di RealityManager.

---

## 3. Autoload

Hanya empat autoload. Sama seperti v1.0.

| Autoload | Tanggung Jawab |
|---|---|
| `SignalBus` | Bus sinyal global. Tidak menyimpan state. |
| `RoomManager` | Load/unload level, checkpoint, snapshot, reset. |
| `AudioManager` | One-shot SFX pool, music crossfade. |
| `DebugConfig` | Toggle debug overlay, cheat keys, log level. |

### 3.1 SignalBus — Sinyal Wajib

```gdscript
# SignalBus.gd
signal character_switched(new_active: String, previous_active: String)
signal character_facing_changed(reality: String, direction: int)
signal character_state_changed(reality: String, new_state: String)
signal link_triggered(link_id: String, source_id: String, target_id: String)
signal link_blocked(link_id: String, reason: String)
signal object_state_changed(object_id: String, new_state: Dictionary)
signal safe_reposition_triggered(reality: String, anchor_position: Vector2)
signal level_completed(level_id: String)
signal room_reset(level_id: String)
signal hazard_entered(reality: String, hazard_id: String)
signal hint_requested(tier: int, level_id: String)
signal debug_overlay_toggled(enabled: bool)
```

**Perubahan dari v1.0:**

- `room_completed` → `level_completed` (level = 2 room).
- `room_reset` tetap (reset per level).
- Tambah `character_facing_changed` untuk feedback visual (sprite flip 4-arah).

---

## 4. Script Responsibilities

| Script | Extends | Tanggung Jawab | Tidak Boleh |
|---|---|---|---|
| `RealityManager.gd` | `Node` | State machine switch, cooldown, pause hazard | Menyelesaikan puzzle |
| `LinkResolver.gd` | `Node` | Terima `LinkRequest`, telusuri link, apply target, rollback | Mengubah posisi karakter |
| `CharacterController.gd` | `CharacterBody2D` | Input 4-arah, facing, interaksi, state karakter | Mengelola level/link |
| `PushableObject.gd` | `AnimatableBody2D` | Push 4-arah, snap grid, emit link | Menentukan validity link |
| `InteractableBase.gd` | `Node2D` | Base class: `interact()`, `on_link_received()` | Movement |
| `Lever.gd` | `InteractableBase` | Toggle state, emit link | — |
| `Plate.gd` | `InteractableBase` | Deteksi weight (karakter + pushable), emit link | — |
| `Button.gd` | `InteractableBase` | One-shot press | — |
| `Door.gd` | `InteractableBase` | Open/close, delay close if character on tile | — |
| `MovingSurface.gd` | `AnimatableBody2D` | Tween antar posisi grid, bawa karakter di atasnya | — |
| `Spike.gd` | `Area2D` | Deteksi karakter, emit hazard_entered | — |
| `RealityLink.gd` | `Resource` | Data link (id, source, target, type, delay, offset_direction) | Runtime state |
| `LevelSnapshot.gd` | `Resource` | Simpan state awal level | — |
| `LevelController.gd` | `Node` | Level lifecycle, checkpoint, exit detection | Movement |
| `HintSystem.gd` | `Node` | Pantau progres, minta hint dari Echo-07 | — |
| `UIDirector.gd` | `Node` | Dengar SignalBus, update UI | Game logic |
| `CameraDirector.gd` | `Node` | Swap active camera, mirror PiP camera | Puzzle logic |

**Perubahan dari v1.0:**

- `CharacterController` tanpa `jump()`. Tambah `facing: int` dan `update_facing()`.
- `MovingPlatform` → `MovingSurface` (top-down, 4 arah).
- `RoomSnapshot` → `LevelSnapshot` (menyimpan 2 room sekaligus).
- `RoomController` → `LevelController`.
- Tambah `Spike.gd` sebagai script terpisah.
- `CameraDirector` sekarang **mirror kamera**, bukan follow character.

---

## 5. Data Structures

### 5.1 RealityLink (Resource)

```gdscript
# RealityLink.gd
class_name RealityLink
extends Resource

enum LinkType { TOGGLE, OFFSET, MIRROR, ONE_WAY, DELAYED, DESTRUCTIBLE }

@export var id: String
@export var source_id: String
@export var target_id: String
@export var type: LinkType
@export var delay: float = 0.0
@export var one_shot: bool = false
@export var offset_direction: Vector2i = Vector2i.ZERO  # 4-arah
@export var mirror_mapping: Dictionary = {}
@export var condition: String = ""
```

**Perubahan:** `offset_direction` sekarang `Vector2i` 4-arah (bukan hanya horizontal).

### 5.2 ResonanceEvent (runtime)

```gdscript
class ResonanceEvent:
	var link_id: String
	var source_id: String
	var target_id: String
	var source_state: Dictionary
	var visited_links: Array[String]
	var depth: int
	var timestamp: float
```

Tidak berubah.

### 5.3 LevelSnapshot (Resource)

```gdscript
# LevelSnapshot.gd
class_name LevelSnapshot
extends Resource

var level_id: String
var character_positions: Dictionary   # {"A": Vector2, "B": Vector2}
var character_facings: Dictionary     # {"A": int, "B": int}
var object_states: Dictionary         # {"plate_01a": {"pressed": false}, ...}
var link_states: Dictionary           # {"link_01": "inactive"}
var delayed_queue: Array
var active_reality: String            # "A" atau "B"
```

**Perubahan:** Tambah `character_facings` (top-down butuh facing).

### 5.4 LinkRequest (struct internal)

```gdscript
class LinkRequest:
	var source_id: String
	var new_state: Dictionary
	var origin: String
```

Tidak berubah.

### 5.5 Facing Enum

```gdscript
# CharacterController.gd
enum Facing { UP, DOWN, LEFT, RIGHT }
var facing: Facing = Facing.DOWN
```

**Baru:** Top-down butuh facing eksplisit untuk push dan interact.

---

## 6. Grid System

### 6.1 Helper Grid

```gdscript
# Grid.gd
class_name Grid

const TILE_SIZE := 32
const SNAP_TOLERANCE := 6.0

static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / TILE_SIZE),
		floori(world_pos.y / TILE_SIZE)
	)

static func grid_to_world(cell: Vector2i, centered: bool = true) -> Vector2:
	var base := Vector2(cell.x * TILE_SIZE, cell.y * TILE_SIZE)
	if centered:
		base += Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	return base

static func is_snapped(world_pos: Vector2) -> bool:
	var snapped := grid_to_world(world_to_grid(world_pos))
	return world_pos.distance_to(snapped) < SNAP_TOLERANCE

# Top-down helpers
static func facing_to_delta(facing: int) -> Vector2i:
	match facing:
		0: return Vector2i(0, -1)   # UP
		1: return Vector2i(0, 1)    # DOWN
		2: return Vector2i(-1, 0)   # LEFT
		3: return Vector2i(1, 0)    # RIGHT
	return Vector2i.ZERO

static func delta_to_facing(delta: Vector2i) -> int:
	if delta.x > 0: return 3  # RIGHT
	if delta.x < 0: return 2  # LEFT
	if delta.y > 0: return 1  # DOWN
	if delta.y < 0: return 0  # UP
	return 1  # default DOWN
```

**Perubahan:** Tambah helper facing ↔ delta.

### 6.2 Pembagian Peran

| Objek | Posisi | Movement | Collision |
|---|---|---|---|
| Karakter | Free (`Vector2`) | 4-dir velocity, tanpa gravity | `CharacterBody2D` |
| Crate | Grid (`Vector2i`) | Tween 0,15s per tile | `AnimatableBody2D` |
| Surface | Grid (`Vector2i`) | Tween | `AnimatableBody2D` |
| Door | Grid + state | Tween open/close | `StaticBody2D` |
| Terrain | TileMapLayer | Statis | TileMap collision |
| Spike | Free / Grid | Statis | `Area2D` |

**Aturan:** Setiap interactable wajib punya `var cell: Vector2i`. Update saat `_ready()` dan setiap movement.

---

## 7. Reality Switching Flow

### 7.1 Sequence (Top-Down)

```text
Player press [Tab] / [Q]
  │
  ▼
CharacterController (active) → RealityManager.request_switch()
  │
  ▼
RealityManager checks:
  ├─ cooldown ready?
  ├─ state == Running?
  └─ not in Repositioning/LevelReset?
  │
  ▼ (valid)
RealityManager.state = Switching
  │
  ├─▶ Active character:
  │     ├─ release grab/pull
  │     ├─ velocity = Vector2.ZERO          ← semua arah
  │     ├─ set_process_input(false)
  │     └─ set state = InactiveFrozen
  │
  ├─▶ Inactive character:
  │     ├─ set_process_input(true)
  │     └─ set state = ActiveControlled
  │
  ├─▶ HazardsA / HazardsB:
  │     └─ toggle process_mode (pause inactive)
  │
  ├─▶ CameraDirector:
  │     ├─ camera_inactive.make_current()
  │     └─ PiPCamera.global_position = camera_inactive.global_position  ← mirror, bukan follow
  │
  ├─▶ UI:
  │     └─ update RealityIndicator, SwitchCooldownBar
  │
  └─▶ emit SignalBus.character_switched(new_active, previous)
  │
  ▼
RealityManager.state = Running
```

**Perubahan dari v1.0:**

- `velocity` di-nol-kan **semua arah** (bukan hanya `velocity.x`).
- `PiPCamera` **mirror kamera**, bukan follow karakter.
- Tidak ada `jump` cleanup.

### 7.2 Cooldown

```gdscript
# RealityManager.gd
const SWITCH_COOLDOWN := 0.25

var _cooldown_timer: float = 0.0

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func can_switch() -> bool:
	return _cooldown_timer <= 0.0 and state == State.RUNNING
```

Sama seperti v1.0.

### 7.3 Hazard Pausing

`HazardsA` dan `HazardsB` adalah grup node spike. Saat switch, `Hazards` milik realita inactive di-set `process_mode = PROCESS_MODE_DISABLED`.

**Catatan top-down:** Spike sebagai `Area2D` — `monitoring` dimatikan saat inactive. Karakter inactive tidak memicu `body_entered`.

---

## 8. Link Resolution Flow

Tidak berubah dari v1.0 secara arsitektur. Perubahan hanya di `offset_direction` yang sekarang 4-arah.

### 8.1 Sequence

```text
Interactable memicu perubahan (mis. plate pressed/released)
  │
  ▼
Interactable.emit_link(source_id, new_state)
  │
  ▼
LinkResolver.receive_request(LinkRequest)
  │
  ├─▶ create ResonanceEvent(visited_links = [], depth = 0)
  │
  ▼
_for_each_link_with_source(source_id):
  │
  ├─▶ if link.id in visited_links: skip
  ├─▶ if depth >= MAX_DEPTH: skip
  ├─▶ if condition not met: skip
  │
  ├─▶ if delay > 0:
  │     └─ push to delayed_queue, return
  │
  ├─▶ target = find_target(link.target_id)
  ├─▶ target_accepts = target.on_link_received(link, new_state)
  │
  ├─▶ if not target_accepts:
  │     ├─ if type == OFFSET: rollback source
  │     └─ emit link_blocked
  │
  ├─▶ else:
  │     ├─ append link.id to visited_links
  │     ├─ depth += 1
  │     ├─ if target emits own link: recurse
  │     └─ emit link_triggered
  │
  ▼
after all links:
  │
  ├─▶ validate character positions
  │     └─ if invalid: SafeReposition
  │
  ▼
emit object_state_changed
```

### 8.2 Offset 4-Arah

```gdscript
func _apply_offset(link: RealityLink, source: PushableObject) -> bool:
	var target: AnimatableBody2D = _find_target(link.target_id)
	var target_cell: Vector2i = target.cell + link.offset_direction

	if not _is_cell_free(target_cell, target):
		source.rollback()
		return false

	target.move_to_cell(target_cell)
	return true
```

### 8.3 Delayed Queue

Sama seperti v1.0. `_delayed_queue` di-clear saat reset.

---

## 9. Safe Reposition (Top-Down)

Dipicu oleh `RealityManager` setelah link resolution, jika karakter inactive invalid.

```gdscript
# RealityManager.gd
func validate_character_position(reality: String) -> void:
	var character: CharacterController = get_character(reality)
	if character.is_position_valid():
		return

	var anchor := _find_nearest_safe_anchor(reality, character.position)
	if anchor == null:
		RoomManager.reset_level()
		return

	character.state = CharacterController.State.REPOSITIONING
	var tween := create_tween()
	tween.tween_property(character, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		character.global_position = anchor.global_position
		character.velocity = Vector2.ZERO
	)
	tween.tween_property(character, "modulate:a", 1.0, 0.15)
	tween.tween_callback(func():
		character.state = CharacterController.State.INACTIVE_FROZEN
		SignalBus.safe_reposition_triggered.emit(reality, anchor.global_position)
	)
```

### 9.1 `is_position_valid()` Top-Down

```gdscript
func is_position_valid() -> bool:
	# 1. Tidak di dalam wall
	if _is_inside_wall():
		return false
	# 2. Tidak di dalam objek solid (crate, door closed)
	if _is_inside_solid_object():
		return false
	# 3. Tidak di spike yang aktif
	if _is_on_active_spike():
		return false
	return true
```

**Perubahan:** Tidak ada cek "di pit" karena tidak ada pit. Ada cek spike.

---

## 10. Level Lifecycle

### 10.1 RoomManager (renamed conceptually to LevelManager tapi keep nama autoload)

```gdscript
# RoomManager.gd (autoload)
var current_level: Node2D
var current_level_id: String
var current_snapshot: LevelSnapshot

func load_level(scene: PackedScene, level_id: String) -> void:
	if current_level:
		current_level.queue_free()
	current_level = scene.instantiate()
	get_tree().get_first_node_in_group("room_slot").add_child(current_level)
	current_level_id = level_id
	_capture_snapshot()
	_position_characters_at_spawn()
	SignalBus.character_switched.emit("A", "")

func reset_level() -> void:
	_restore_snapshot()
	SignalBus.room_reset.emit(current_level_id)

func _capture_snapshot() -> void:
	current_snapshot = LevelSnapshot.new()
	current_snapshot.level_id = current_level_id
	# iterate characters dan interactables (A + B), simpan state
	...
```

### 10.2 LevelController & Exit Detection

```gdscript
# LevelController.gd
extends Node

var _exits_reached: Dictionary = {"A": false, "B": false}

func _ready() -> void:
	SignalBus.link_triggered.connect(_on_exit_event)

func _on_exit_event(link_id: String, source_id: String, _target_id: String) -> void:
	if source_id == "exit_a": _exits_reached["A"] = true
	if source_id == "exit_b": _exits_reached["B"] = true
	_check_complete()

func _check_complete() -> void:
	if _exits_reached["A"] and _exits_reached["B"]:
		SignalBus.level_completed.emit(get_parent().level_id)
```

**Perubahan:** Level complete butuh **kedua exit** (A dan B), bukan per-room.

---

## 11. Camera & PiP (Top-Down)

### 11.1 Fixed Camera per Room

```gdscript
# CameraA / CameraB — set di editor atau via script
extends Camera2D

func _ready() -> void:
	position_smoothing_enabled = false
	position_smoothing_speed = 0.0
	zoom = Vector2(1.0, 1.0)
	# limit di-set per level
```

Setiap room punya camera sendiri. Saat switch, `make_current()` dipanggil pada kamera realita aktif.

**Tidak ada follow.** Posisi kamera = center room. Contoh Level 1:

- CameraA: `position = (256, 192)`, limit 0–512 × 0–384.
- CameraB: `position = (10256, 192)`, limit 10000–10512 × 0–384.

### 11.2 PiP Camera

```gdscript
# CameraDirector.gd
extends Node

@export var pip_camera: Camera2D

func _on_switch(new_active: String, _previous: String) -> void:
	var inactive_camera: Camera2D = get_inactive_camera(new_active)
	pip_camera.global_position = inactive_camera.global_position
	pip_camera.limit_left = inactive_camera.limit_left
	pip_camera.limit_right = inactive_camera.limit_right
	pip_camera.limit_top = inactive_camera.limit_top
	pip_camera.limit_bottom = inactive_camera.limit_bottom
	pip_camera.zoom = inactive_camera.zoom
	pip_camera.make_current()  # untuk SubViewport
```

**Perubahan kunci dari v1.0:** PiP **mirror kamera realita inactive**, **tidak follow karakter inactive**. Ini karena kamera top-down fixed — seluruh room terlihat.

### 11.3 SubViewport Setup

- `SubViewportContainer` di UI, ukuran `320×240` (rasio 4:3, sesuai room 16×12).
- `SubViewport.size = Vector2i(640, 480)` (2x untuk crisp).
- `SubViewport.render_target_update_mode = UPDATE_ALWAYS`.
- `SubViewport.world_2d` = sama dengan main viewport.
- `PiPCamera` di dalam SubViewport.
- Border 3px dengan warna sesuai realita inactive.

### 11.4 Desaturasi Realita Inactive

Gunakan `CanvasModulate` per realita:

```gdscript
# Saat switch
reality_inactive.modulate = Color(0.6, 0.6, 0.7)  # desaturasi + tint
reality_active.modulate = Color(1, 1, 1)
```

Atau shader global (`CanvasLayer` dengan `ColorRect` + `BackBufferCopy`). Untuk MVP, `CanvasModulate` per `Node2D` root realita cukup.

---

## 12. UI Structure

```text
UI (CanvasLayer)
├── RealityIndicator (Label / Icon)
│   └─ "REALITA A" atau "REALITA B", warna berbeda
├── SwitchCooldownBar (ProgressBar)
│   └─ Radial atau horizontal
├── HintPanel (PanelContainer)
│   └─ Teks hint Echo-07
├── DebugOverlay (PanelContainer, hidden)
│   └─ Toggle F1
└── PauseMenu (Control)
```

Sama seperti v1.0. `UIDirector` hanya membaca `SignalBus`, tidak punya logika game.

---

## 13. Debug Overlay (Top-Down)

```text
[RealityManager]
  state: RunningA
  cooldown: 0.00
  active: A
[Characters]
  A: pos=(320, 480) cell=(10,15) facing=DOWN state=ActiveControlled
  B: pos=(10320, 480) cell=(10,15) facing=DOWN state=InactiveFrozen
[Level]
  id: Level01
  exits: A=false B=false
[Links]
  link_plate_to_door Toggle plate_1a -> door_1b [pressed->open]
[Delayed Queue]
  (empty)
[Safe Reposition]
  last: none
```

**Perubahan:** Tampilkan `facing` dan `exits` status.

Toggle: `F1`. Cheat keys sama seperti v1.0, tapi **hapus cheat "toggle invulnerability"** (tidak ada health di MVP).

---

## 14. Folder Structure

```text
res://
├── autoload/
│   ├── SignalBus.gd
│   ├── RoomManager.gd
│   ├── AudioManager.gd
│   └── DebugConfig.gd
├── core/
│   ├── RealityManager.gd
│   ├── LinkResolver.gd
│   ├── CameraDirector.gd
│   ├── Grid.gd
│   └── LevelController.gd
├── characters/
│   ├── CharacterController.gd
│   └── CharacterController.tscn
├── interactables/
│   ├── InteractableBase.gd
│   ├── PushableObject.gd
│   ├── Lever.gd
│   ├── Plate.gd
│   ├── Button.gd
│   ├── Door.gd
│   ├── MovingSurface.gd
│   └── Spike.gd
├── data/
│   ├── RealityLink.gd
│   ├── LevelSnapshot.gd
│   └── LevelConfig.gd
├── ui/
│   ├── UIDirector.gd
│   ├── DebugOverlay.gd
│   └── HintPanel.gd
├── levels/
│   ├── Level01.tscn
│   ├── Level02.tscn
│   └── ...
├── assets/
│   ├── sprites/
│   │   └── top_down/
│   ├── tiles/
│   │   └── top_down/
│   └── audio/
└── Main.tscn
```

**Perubahan:** `rooms/` → `levels/`, `assets/tiles/top_down/`, tambah `Spike.gd`.

---

## 15. Implementation Order (Dependency Graph)

```text
1. SignalBus + DebugConfig (autoload kosong)
   ↓
2. Grid.gd (helper + facing delta)
   ↓
3. CharacterController (4-dir movement, facing, tanpa jump)
   ↓
4. Main.tscn skeleton + Level01 greybox + CameraA/B fixed
   ↓
5. RealityManager (switch, cooldown, camera swap, PiP mirror)
   ↓
6. UIDirector (RealityIndicator + SwitchCooldownBar)
   ↓
7. InteractableBase + Plate (deteksi karakter + pushable)
   ↓
8. LinkResolver (toggle sederhana)
   ↓
9. Door (dengan delay close jika karakter di tile)
   ↓
10. LevelController + ExitZone + RoomManager (level load/complete)
	↓  ← GAMELOOP PERTAMA HIDUP (Level 1 selesai)
11. PushableObject (4-arah) + Spike
	↓
12. LinkResolver offset 4-arah + rollback
	↓
13. Level02 greybox
	↓  ← GAMELOOP DENGAN 2 LEVEL
14. Safe Reposition + LevelSnapshot + Reset
	↓
15. HintSystem + HintPanel
	↓
16. Delayed + OneWay + Mirror + Destructible link
	↓
17. Level03–04 greybox
	↓  ← VERTICAL SLICE LENGKAP
18. DebugOverlay final
	↓
19. AudioManager + placeholder SFX
	↓  ← PROTOTYPE PLAYABLE
```

**Gate wajib:**

- **Gate 1** (setelah step 10): Level 1 playable end-to-end (spawn → switch → plate → door → exit A + exit B).
- **Gate 2** (setelah step 13): Level 1 dan 2 playable berurutan.

---

## 16. Anti-Patterns (Hindari)

| Anti-pattern | Kenapa | Alternatif |
|---|---|---|
| `is_on_floor()` / `gravity` | Tidak ada vertical di top-down | Hapus total dari CharacterController |
| `jump_velocity`, `Space` untuk jump | Tidak ada jump di MVP | Hapus dari input map |
| Camera follow karakter | Kamera fixed per room | Set posisi ke center room |
| PiP follow karakter inactive | PiP mirror kamera realita inactive | Set posisi = kamera inactive |
| Smoothing camera | Kamera fixed | `position_smoothing_enabled = false` |
| Diagonal input | 4-directional only | Reject diagonal di input handler |
| Physics push crate | Rollback susah, tidak deterministik | Grid push + tween 0,15s |
| `get_node("../../Character")` | Rapuh | Gunakan grup + `SignalBus` |
| Logika puzzle di `AnimationPlayer` | State desync | Logika di script, animasi visual saja |
| `_process` untuk validasi grid | Boros | Reaktif via signal |
| `Area2D` untuk semua interaksi | Tidak bisa rollback | `InteractableBase` dengan kontrak eksplisit |
| Menyimpan state di UI | UI harus reaktif | UI baca dari `SignalBus` |
| Hardcode link di scene | Sulit tweak | `RealityLink` resource |
| Satu `World2D` per realita | Kompleks untuk solo | Satu `World2D`, offset spasial |
| Multi-incoming link di MVP | Debug nightmare | Satu target, satu incoming |

---

## 17. Kontrak Antar-Sistem (Ringkas)

| Dari | Ke | Mekanisme | Payload |
|---|---|---|---|
| Input | CharacterController | Input event | aksi (4-dir, E, Tab) |
| CharacterController | RealityManager | Direct call | `request_switch()` |
| Interactable | LinkResolver | Direct call | `LinkRequest` |
| LinkResolver | Target | Direct call | `on_link_received(link, state)` |
| LinkResolver | SignalBus | Signal | `link_triggered`, `link_blocked` |
| RealityManager | SignalBus | Signal | `character_switched`, `character_facing_changed` |
| RealityManager | CameraDirector | Direct call | `swap_camera()`, `mirror_pip()` |
| LevelController | RoomManager | Direct call | `reset_level()` |
| RoomManager | SignalBus | Signal | `room_reset`, `level_completed` |
| SignalBus | UIDirector | Signal | semua event UI |
| SignalBus | AudioManager | Signal | semua event SFX |

**Prinsip:** direct call untuk hal yang **harus sinkron** (switch, link resolution). Signal untuk **asinkron** (UI, audio, analytics).

---

## 18. Parameter Teknis Awal (Top-Down)

| Parameter | Nilai | Catatan |
|---|---|---|
| Tile size | 32 px | Standar |
| Room size | 16×12 tile (512×384 px) | Fixed per room |
| Viewport aktif | 1920×1080 | Skala 3.75x room; atau 512×384 untuk pixel-perfect |
| Zoom kamera | 1.0 | Asumsi viewport di-scale |
| PiP size | 320×240 | 4:3 |
| PiP subviewport | 640×480 | 2x render |
| **Character speed** | **200 px/s** | 4-arah, terasa responsif tapi tidak terlalu cepat |
| **Character acceleration** | **0 (instant)** | Tidak ada inertia |
| **Diagonal input** | **Ditolak** | Hanya 4-arah |
| **Gravity** | **0** | Tidak ada |
| **Jump velocity** | **Tidak ada** | Dihapus |
| Switch cooldown | 0.25 s | Spec |
| Push tween | 0.15 s | Spec |
| Safe reposition fade | 0.3 s | Spec |
| **Camera smoothing** | **0 (fixed)** | Tidak ada smoothing |
| **PiP update** | **On switch only** | Tidak perlu tiap frame |

---

## 19. Roadmap Dokumen

| Langkah | Dokumen | Status |
|---|---|---|
| 1 | Spesifikasi Mekanik Formal v2.0 (Top-Down) | Selesai |
| 2 | Level Design — Level 1 (2 room) | Selesai |
| 2b | Level Design — Level 2–4 (6 room) | Belum |
| 3 | Arsitektur Godot 4 v2.0 (Top-Down) | **Selesai (dokumen ini)** |
| 4 | Boss Design Document | Belum (ditunda) |
| 5 | Prototype Backlog v2.0 | Belum — berikutnya |

---

## 20. Yang Ditunda

Tidak termasuk di MVP:

- Timed button
- Multi-button door
- Hazard pit / lava / laser
- Dash / roll / dodge
- Grab / throw
- Boss encounter
- Save/load
- Accessibility penuh
