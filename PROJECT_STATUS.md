# PROJECT_STATUS.md
# Godot 4 — Splitbound Top-Down Puzzle

## Current Sprint: Sprint 1 — Foundation & Greybox (S1-01 hingga S1-07)

## Last Completed Task:
S1-07: UIDirector — Indikator Realita, SwitchCooldownBar, desaturasi via CanvasModulate
(S1-06: RealityManager — State machine switch + cooldown, S1-05: Level01 Greybox, 
 S1-04: CharacterController — 4-dir movement + facing, S1-03: Grid Helper + Facing, 
 S1-01: Scaffold project + autoload + Main.tscn)

## Next Task:
S2-01: InteractableBase + Plate (plate aktif/dibatalkan, emit LinkRequest)
*(Setelah ini: Door delay close, MovingSurface, Spike)*

## Known Issues / Bugs:
1. Input map belum terkonfigurasi manual di Project Settings → Input Map
   - 7 aksi: move_up/down/left/right, interact, switch_reality (Tab+Q), reset (R)
   - Tanpa jump
2. Beberapa class_name Script belum terdaftar dengan benar saat load scene headless — 
   solusi: pakai `ext_resource` di .tscn atau jalankan melalui editor GUI
3. Level01.gd parsing error di baris 41 — perbaiki indentasi/structure
4. RealityManager.gd reference ke CharacterController harus di-verify di scene editor

## Important Context (for AI):
- **Target Engine**: Godot 4.5.stable (config_version=5, renderer Forward Plus)
- **Game Genre**: Top-down puzzle (tanpa gravity/jump)
- **Core Mechanic**: Reality switching (Tab/Q) antara karakter A dan B
- **Grid System**: TILE_SIZE=32, grid 16×12 per room, SNAP_TOLERANCE=6.0
- **Autoload**: 4 script kosong — SignalBus, RoomManager, AudioManager, DebugConfig
- **Scene Tree**: Main.tscn (WorldRoot + RoomSlot) → Level01.tscn (RealityA/B)
- **Key Folders**: 
  - res://autoload/ — 4 scriptpokok
  - res://core/ — Grid, RealityManager, CameraDirector, UIDirector
  - res://characters/ — CharacterController
  - res://interactables/ — InteractableBase, Plate
  - res://levels/ — Level01 greybox
  - res://assets/ — tileset dan sprite (belum di-setup eksplisit)
- **Input**: Dikonfigurasi manual di Project Settings → Input Map
- **State Machine**: RealityManager runningA/runningB/switching/levelReset
- **No Physics**: Tanpa gravity, tanpa jump, tanpa is_on_floor()
- **PiP Camera**: mirror kamera inactive, bukan follow karakter
- **Desaturasi**: CanvasModulate per realita: aktif(1,1,1), inactive(0.6,0.6,0.7)
- **UI**: CanvasLayer dengan Label REALITA A/B, ProgressBar cooldown, SubViewport 320×240 untuk PiP

---
*File ini diupdate di akhir setiap major task oleh AI agent.*
