# Splitbound — Prototype Backlog v2.0 (Top-Down)

> **Status:** Draft v2.0
> **Ruang Lingkup:** Backlog eksekusi solo programmer untuk prototype MVP
> **Target:** Gameloop playable Level 1–4 (8 room)
> **Perubahan dari v1.0:** Top-down, hapus jump/gravity, Level = 2 room, 4-directional
> **Terkait:** Mekanik Formal v2.0 (Langkah 1), Level 1 Design (Langkah 2), Arsitektur Godot v2.0 (Langkah 3)

---

## 0. Perubahan dari v1.0

| Aspek | v1.0 | v2.0 |
|---|---|---|
| Perspektif | Side-view | **Top-Down** |
| Movement | Horizontal + jump + gravity | **4-directional, tanpa gravity** |
| Jump task | Ada | **Dihapus** |
| Facing system | Tidak ada | **Wajib** (`enum Facing`) |
| Kamera | Follow + smoothing | **Fixed per room** |
| PiP | Follow karakter inactive | **Mirror kamera realita inactive** |
| Unit level | 1 room | **1 level = 2 room (A + B)** |
| Gate 1 | Room 1 playable | **Level 1 playable** (Room 1A + 1B) |
| Gate 2 | Room 1–2 playable | **Level 1–2 playable** (4 room) |
| Push direction | Horizontal | **4-directional** |
| Plate weight source | Karakter saja | **Karakter + pushable** |
| Door close | Langsung | **Delay jika karakter di tile** |
| Hazard | Spike pit + fall | **Spike tile saja** |
| Boss | Ada di roadmap | **Ditunda** |

---

## 1. Cara Membaca Backlog Ini

Setiap task punya format:

```text
[ID] Judul
  Ref     : Langkah 3 §15 step N / Langkah 1 §X.Y / Langkah 2 Level N
  Est     : estimasi hari (solo)
  Deps    : task yang harus selesai dulu
  DoD     : Definition of Done (checklist)
  Test    : cara verifikasi manual
```

**Aturan eksekusi solo:**

1. Selesaikan satu task sampai DoD terpenuhi sebelum mulai task lain.
2. Kalau task >1 hari, pecah lagi.
3. Commit per task, bukan per sprint.
4. Update backlog jika ada perubahan scope.
5. **Gate tidak boleh dilompati** (lihat Arsitektur Godot §15).

**Estimasi total:**

| Fase | Sprint | Estimasi |
|---|---|---|
| Fase 1 — Fondasi | Sprint 1 | 5–6 hari |
| Fase 2 — Gameloop Level 1 | Sprint 2 | 6–7 hari |
| **Gate 1** | — | — |
| Fase 3 — Push + Level 2 | Sprint 3 | 6–7 hari |
| **Gate 2** | — | — |
| Fase 4 — Robustness | Sprint 4 | 4–5 hari |
| Fase 5 — Vertical Slice Level 3–4 | Sprint 5–6 | 10–12 hari |
| Fase 6 — Polish | Sprint 7 | 5–6 hari |
| **Total** | — | **36–50 hari kerja** (~8–10 minggu) |

**Catatan:** Sedikit lebih lama dari v1.0 karena Level = 2 room (content 2x) dan facing system + 4-dir push menambah kompleksitas.

---

## 2. Definisi "Selesai" Global

Task dianggap selesai jika:

- Kode lolos `gdscript` warning level default tanpa warning baru.
- Node/script punya komentar header singkat.
- Bisa dijalankan tanpa error di Godot editor (F5).
- Debug overlay menampilkan state yang relevan.
- Acceptance criteria terpenuhi.
- Di-commit dengan pesan deskriptif.

---

## 3. Fase 1 — Fondasi (Sprint 1)

**Tujuan:** Sistem dasar berdiri; karakter 4-dir bisa bergerak; kamera fixed per room.
**Ref:** Arsitektur Godot v2.0 §15 step 1–4.
**Estimasi:** 5–6 hari.

---

### [S1-01] Setup Project & Autoload Kosong

**Ref:** Arsitektur §3, §14
**Est:** 0.5 hari
**Deps:** —
**DoD:**
- [ ] Project Godot 4.3 dibuat, folder structure sesuai §14 (termasuk `levels/`, `assets/tiles/top_down/`).
- [ ] Autoload `SignalBus`, `RoomManager`, `AudioManager`, `DebugConfig` terdaftar (script kosong dengan header).
- [ ] `Main.tscn` dengan `WorldRoot` dan `RoomSlot` (Node2D kosong).
- [ ] Input map: `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `switch_reality`, `reset`. **Tanpa `jump`.**
- [ ] `.gitignore` untuk `.godot/`, `*.import`, export folder.

**Test:** Buka project, F5, tidak ada error.

---

### [S1-02] SignalBus — Definisi Sinyal

**Ref:** Arsitektur §3.1
**Est:** 0.25 hari
**Deps:** S1-01
**DoD:**
- [ ] Semua sinyal di §3.1 dideklarasikan, termasuk `character_facing_changed`.
- [ ] Tidak ada logika di `SignalBus.gd`, hanya deklarasi sinyal.
- [ ] Komentar per sinyal.

**Test:** Script parse tanpa warning.

---

### [S1-03] Grid Helper + Facing

**Ref:** Arsitektur §6.1
**Est:** 0.5 hari
**Deps:** S1-01
**DoD:**
- [ ] `Grid.gd` dengan `world_to_grid`, `grid_to_world`, `is_snapped`.
- [ ] Helper `facing_to_delta(facing: int) -> Vector2i` dan `delta_to_facing(delta: Vector2i) -> int`.
- [ ] Konstanta `TILE_SIZE = 32`, `SNAP_TOLERANCE = 6.0`.
- [ ] Enum `Facing { UP, DOWN, LEFT, RIGHT }`.

**Test:** Konversi bolak-balik konsisten; facing→delta→facing roundtrip benar.

---

### [S1-04] CharacterController — 4-Dir Movement + Facing

**Ref:** Arsitektur §4, §18; Mekanik v2.0 §2.2
**Est:** 1.5 hari
**Deps:** S1-03
**DoD:**
- [ ] `CharacterBody2D` dengan sprite placeholder (kotak 24×24 untuk top-down).
- [ ] Move 4-arah (`WASD` / `←↑→↓`), speed 200 px/s.
- [ ] **Tidak ada** `gravity`, `jump`, `is_on_floor()`.
- [ ] `velocity = input_dir * speed`, `move_and_slide()`.
- [ ] Diagonal input ditolak (prioritas: horizontal dulu, atau last input wins — pilih satu dan konsisten).
- [ ] `facing: Facing` di-track dari input gerak terakhir.
- [ ] Emit `SignalBus.character_facing_changed` saat facing berubah.
- [ ] State enum: `ACTIVE_CONTROLLED`, `INACTIVE_FROZEN`, `INACTIVE_ON_MOVING_SURFACE`, `REPOSITIONING`, `DEAD`.
- [ ] Method `set_input_enabled(bool)`.
- [ ] Method `is_position_valid() -> bool` (stub: return true dulu).
- [ ] Sprite flip/rotate sesuai facing (placeholder: 4 sprite arah atau flip horizontal).

**Test:** Karakter bisa jalan 4 arah di room kosong; facing update; diagonal tidak bergerak diagonal (hanya satu sumbu).

**Anti-pattern check:** Tidak ada `gravity`, `jump_velocity`, atau `is_on_floor()` di script.

---

### [S1-05] Level01 Greybox (Room 1A + Room 1B) + Fixed Cameras

**Ref:** Level 1 Design §3–4; Arsitektur §2, §11.1
**Est:** 1.5 hari
**Deps:** S1-04
**DoD:**
- [ ] `Level01.tscn` dengan `RealityA` (pos 0,0) dan `RealityB` (pos 10000,0).
- [ ] `TileMapLayer` per realita dengan terrain top-down (grid 16×12 sesuai Level 1 Design).
- [ ] `SpawnA`, `SpawnB`, `ExitZoneA`, `ExitZoneB`, `SafeAnchorsA/B`.
- [ ] `CameraA`, `CameraB` fixed: `position_smoothing_enabled = false`, zoom 1.0, limit sesuai room.
- [ ] Dua `CharacterController` instance (A di Room 1A spawn, B di Room 1B spawn).
- [ ] TileMap collision: wall solid, floor walkable.

**Test:** Load Level01, karakter di spawn masing-masing; kamera mengunci room; switch kamera manual berfungsi.

---

### [S1-06] RealityManager — Switch Dasar + PiP Mirror

**Ref:** Arsitektur §7, §11.2; Mekanik v2.0 §2.5
**Est:** 1 hari
**Deps:** S1-04, S1-05
**DoD:**
- [ ] State machine `RunningA`, `RunningB`, `Switching`, `LevelReset`. **Tanpa `BossTransition`.**
- [ ] `request_switch()` validasi cooldown 0.25s.
- [ ] Saat switch: disable input karakter lama, enable input karakter baru, `velocity = Vector2.ZERO` (semua arah), `make_current()` kamera.
- [ ] Emit `SignalBus.character_switched(new, prev)`.
- [ ] `PiPCamera.global_position = camera_inactive.global_position` (mirror, bukan follow).
- [ ] PiP limit di-copy dari kamera inactive.
- [ ] Input switch: `Tab` dan `Q`.

**Test:** Tekan `Tab`, kontrol berpindah, kamera pindah, PiP menampilkan room inactive.

---

### [S1-07] UIDirector — Indikator Realita

**Ref:** Arsitektur §12
**Est:** 0.5 hari
**Deps:** S1-06
**DoD:**
- [ ] `UI` CanvasLayer dengan label "REALITA A"/"REALITA B".
- [ ] `SwitchCooldownBar`.
- [ ] UIDirector dengar `character_switched`, update label + warna.
- [ ] Desaturasi realita inactive via `CanvasModulate` per realita (0.6, 0.6, 0.7) — aktif (1,1,1).

**Test:** Tekan `Tab`, label + warna + desaturasi berubah.

---

**Gate sementara Sprint 1:** Karakter bisa jalan 4-dir, switch, PiP mirror, desaturasi bekerja.

---

## 4. Fase 2 — Gameloop Level 1 (Sprint 2)

**Tujuan:** Level 1 (Room 1A + 1B) playable end-to-end.
**Ref:** Arsitektur §15 step 7–10; Level 1 Design §6.
**Estimasi:** 6–7 hari.

---

### [S2-01] InteractableBase

**Ref:** Arsitektur §4, §8
**Est:** 0.5 hari
**Deps:** S1-04
**DoD:**
- [ ] Class `InteractableBase extends Node2D`.
- [ ] Properti `id: String`, `cell: Vector2i`, `enabled: bool`.
- [ ] Method virtual `interact() -> void`, `on_link_received(link, state) -> bool`.
- [ ] Helper `_update_cell()`.

**Test:** Script parse, bisa di-extend.

---

### [S2-02] Plate — Character + Pushable Weight

**Ref:** Mekanik v2.0 §3.2, §3.4; Arsitektur §4
**Est:** 1 hari
**Deps:** S2-01
**DoD:**
- [ ] `Plate extends InteractableBase`.
- [ ] `Area2D` mendeteksi `CharacterController` **dan** `PushableObject` di atasnya.
- [ ] State `pressed`/`released`.
- [ ] Emit `LinkRequest` saat state berubah.
- [ ] Karakter inactive (frozen) tetap dihitung weight.
- [ ] Feedback visual: tile turun + warna hijau saat pressed.

**Test:** Karakter di atas plate → pressed. Switch → tetap pressed. Pindah → released.

---

### [S2-03] LinkResolver — Toggle Sederhana

**Ref:** Arsitektur §8; Mekanik v2.0 §3.7
**Est:** 1 hari
**Deps:** S2-02
**DoD:**
- [ ] `LinkResolver` terima `LinkRequest`.
- [ ] Cari `RealityLink` resource dengan `source_id` cocok.
- [ ] Untuk `TOGGLE`: panggil `target.on_link_received()`.
- [ ] Jika target reject → emit `link_blocked`.
- [ ] Jika success → emit `link_triggered`.
- [ ] `visited_links` mencegah loop. Max depth 2.

**Test:** Plate di A → door di B berubah state.

---

### [S2-04] RealityLink Resource

**Ref:** Arsitektur §5.1
**Est:** 0.5 hari
**Deps:** S2-01
**DoD:**
- [ ] `RealityLink extends Resource` dengan semua field §5.1.
- [ ] `offset_direction: Vector2i` (4-arah, bukan hanya horizontal).
- [ ] Editor-friendly.
- [ ] Bisa di-save/load sebagai `.tres`.

**Test:** Buat `link_plate_to_door.tres`, isi field, save.

---

### [S2-05] Door — Delay Close if Character on Tile

**Ref:** Mekanik v2.0 §3.6; Level 1 Design §7.1
**Est:** 1 hari
**Deps:** S2-01
**DoD:**
- [ ] `Door extends InteractableBase`.
- [ ] State `open`/`closed`.
- [ ] `on_link_received` dengan `TOGGLE`: set target state.
- [ ] Collision block saat closed.
- [ ] **Delay close logic:** saat menerima `close` tapi `Area2D` mendeteksi karakter di tile → tunda sampai kosong, lalu close 0.15s.
- [ ] Tween animasi 0.15s (visual only, state instan setelah tween).

**Test:** Karakter di tile door saat door diminta close → door menunggu sampai karakter keluar.

---

### [S2-06] Level01 Scene — Wiring Full

**Ref:** Level 1 Design §5, §6
**Est:** 1 hari
**Deps:** S1-07, S2-02 sampai S2-05
**DoD:**
- [ ] `Level01.tscn` dilengkapi `Plate01` di Room 1A, `Door01` di Room 1B.
- [ ] `Links` node berisi `RealityLink` `link_plate_to_door`.
- [ ] ExitZone A dan B dengan script emit signal.
- [ ] Wiring: plate → link → door → exit B.

**Test:** Ikuti solusi Level 1 Design §6.1, selesaikan Level 1.

---

### [S2-07] LevelController & LevelManager — Load + Exit

**Ref:** Arsitektur §10
**Est:** 1 hari
**Deps:** S2-06
**DoD:**
- [ ] `LevelController` track `exits_reached = {"A": false, "B": false}`.
- [ ] Saat kedua exit tercapai → emit `SignalBus.level_completed(level_id)`.
- [ ] `RoomManager.load_level(scene, id)` instantiate di `RoomSlot`.
- [ ] `RoomManager` dengar `level_completed`, log "Level X complete".
- [ ] ExitZone emit `SignalBus.link_triggered("exit", "exit_a"/"exit_b", "level_complete")`.

**Test:** Selesaikan Level 1, log "Level01 complete" muncul.

---

### [S2-08] Integration Test Level 1

**Ref:** Level 1 Design §11; Mekanik v2.0 §5 T1–T6
**Est:** 0.5 hari
**Deps:** S2-07
**DoD:**
- [ ] Level 1 selesai tanpa cheat.
- [ ] Switch berfungsi di setiap titik.
- [ ] Plate tetap pressed saat A inactive.
- [ ] Door delay close berfungsi (A step off plate saat B di tile door).
- [ ] Tidak ada softlock.
- [ ] Playtest 3x, median solve <75 detik.
- [ ] Catat masalah UX di `playtest_notes.md`.

**Test:** Mainkan 3 kali, catat waktu.

---

### ✅ GATE 1 — Syarat Lulus

> Dari **Arsitektur Godot v2.0 §15**: "Level 1 playable end-to-end (spawn → switch → plate → door → exit A + exit B)."

**Checklist Gate 1:**

- [ ] Level 1 (Room 1A + 1B) playable end-to-end.
- [ ] Switch + toggle link + plate + door berfungsi.
- [ ] PiP mirror kamera inactive.
- [ ] Desaturasi realita inactive.
- [ ] UI indikator realita aktif.
- [ ] Tidak ada crash/error.
- [ ] Median playtest 3x <90 detik.
- [ ] Tidak ada input jump (verifikasi input map).

**Jika Gate 1 lulus:** lanjut Sprint 3.
**Jika gagal:** perbaiki Level 1 dulu.

---

## 5. Fase 3 — Push + Level 2 (Sprint 3)

**Tujuan:** Pushable 4-arah + offset link + spike + Level 2 playable.
**Ref:** Arsitektur §15 step 11–13.
**Estimasi:** 6–7 hari.

---

### [S3-01] PushableObject — 4-Directional Push

**Ref:** Mekanik v2.0 §3.3; Arsitektur §6.2
**Est:** 2 hari
**Deps:** S2-01
**DoD:**
- [ ] `PushableObject extends AnimatableBody2D`.
- [ ] `cell: Vector2i`, `move_to_cell(target: Vector2i)` via tween 0.15s.
- [ ] Validasi 4-arah: cell kosong, tidak ada karakter, tidak ada objek solid, tidak spike aktif.
- [ ] Method `rollback()`.
- [ ] Interaksi `E`: push menjauh dari player, pull mendekat (ke arah facing player).
- [ ] Block input movement selama animasi (0.15s).
- [ ] Karakter yang berdiri di atas pushable ikut bergerak (pushable sebagai `AnimatableBody2D`).

**Test:** Push crate 4 arah; push ke wall ditolak; push ke spike ditolak.

---

### [S3-02] LinkResolver — Offset 4-Arah + Rollback

**Ref:** Mekanik v2.0 §3.7; Arsitektur §8.2
**Est:** 1 hari
**Deps:** S2-03, S3-01
**DoD:**
- [ ] Handle `OFFSET`: `target.move_to_cell(cell + link.offset_direction)`.
- [ ] `offset_direction` bisa 4 arah (atas/bawah/kiri/kanan).
- [ ] Jika target cell blocked → `source.rollback()`, emit `link_blocked`.
- [ ] Chain depth tetap.

**Test:** Push crate A → moving surface B geser. Push ke blocked → rollback.

---

### [S3-03] MovingSurface (Rename dari MovingPlatform)

**Ref:** Mekanik v2.0 §3.2; Arsitektur §4
**Est:** 1 hari
**Deps:** S2-01
**DoD:**
- [ ] `MovingSurface extends AnimatableBody2D` (nama baru).
- [ ] `move_to_cell()` via tween.
- [ ] Bisa bergerak 4 arah (bukan hanya vertikal).
- [ ] Karakter di atas ikut bergerak.
- [ ] Inactive character ikut terbawa.

**Test:** Surface bergeser horizontal dan vertikal; karakter ikut.

---

### [S3-04] Spike — Hazard Tile

**Ref:** Mekanik v2.0 §3.2; Arsitektur §4
**Est:** 0.5 hari
**Deps:** S1-06
**DoD:**
- [ ] `Spike extends Area2D`.
- [ ] Berada di grup `hazards_a` / `hazards_b`.
- [ ] Pause saat realita inactive (`monitoring = false`, `process_mode = DISABLED`).
- [ ] Sentuh karakter aktif → emit `SignalBus.hazard_entered` → reset level.
- [ ] Karakter inactive di spike paused → tidak mati.

**Test:** Karakter aktif menyentuh spike → mati + reset. Karakter inactive tidak mati.

---

### [S3-05] Level02 Greybox (Room 2A + Room 2B)

**Ref:** Level 2 Design (belum dibuat); Mekanik v2.0 §3.6 (Offset)
**Est:** 1.5 hari
**Deps:** S3-02, S3-03, S3-04
**DoD:**
- [ ] `Level02.tscn` dengan 2 room top-down.
- [ ] Puzzle: push crate di A → moving surface di B bergeser ke exit.
- [ ] `Links`: `Offset crate_2a -> surface_2b`.
- [ ] ExitZone A dan B.
- [ ] Safe anchors.

**Test:** Selesaikan Level 2 (desain detail menyusul di Level 2 Design doc).

---

### [S3-06] Level Transition Sederhana

**Ref:** Arsitektur §10
**Est:** 0.5 hari
**Deps:** S2-07, S3-05
**DoD:**
- [ ] `RoomManager` mapping `level_id -> next_level_scene`.
- [ ] Saat `level_completed` → fade 0.3s → load level berikutnya → fade in.
- [ ] Reset posisi karakter ke spawn level baru.
- [ ] Reset desaturasi state.

**Test:** Level 1 → Level 2 otomatis.

---

### [S3-07] Integration Test Level 1–2

**Ref:** Mekanik v2.0 §5 T7–T8
**Est:** 0.5 hari
**Deps:** S3-06
**DoD:**
- [ ] Level 1 → Level 2 berurutan playable.
- [ ] Push 4 arah teruji.
- [ ] Offset link + rollback teruji.
- [ ] Spike kill + reset teruji.
- [ ] Tidak ada softlock.

---

### ✅ GATE 2 — Syarat Lulus

> Dari **Arsitektur Godot v2.0 §15**: "Level 1 dan 2 playable berurutan."

**Checklist Gate 2:**

- [ ] Level 1 + 2 playable berurutan.
- [ ] Push 4 arah + offset link berfungsi.
- [ ] Spike sebagai hazard berfungsi.
- [ ] Level transition otomatis.
- [ ] Median solve Level 2 <90 detik.
- [ ] Tidak ada softlock.

**Jika Gate 2 lulus:** gameloop dasar terbukti.

---

## 6. Fase 4 — Robustness (Sprint 4)

**Tujuan:** Reset, safe reposition, hint dasar.
**Ref:** Arsitektur §15 step 14–15.
**Estimasi:** 4–5 hari.

---

### [S4-01] LevelSnapshot + Reset

**Ref:** Mekanik v2.0 §2.11; Arsitektur §5.3, §10.1
**Est:** 1 hari
**Deps:** S3-06
**DoD:**
- [ ] `LevelSnapshot` resource: posisi karakter, facing, state objek (A + B), state link one-shot, queue delayed, realita aktif.
- [ ] `RoomManager._capture_snapshot()` dipanggil saat level load.
- [ ] `RoomManager.reset_level()` restore semua state.
- [ ] Input `R` memicu reset.
- [ ] Queue delayed clear.

**Test:** Tekan `R` di tengah Level 2 → semua kembali ke awal.

---

### [S4-02] Safe Reposition

**Ref:** Mekanik v2.0 §2.7; Arsitektur §9
**Est:** 1 hari
**Deps:** S4-01
**DoD:**
- [ ] `SafeAnchorsA/B` (Marker2D) di setiap level.
- [ ] `RealityManager.validate_character_position()` dipanggil setelah link resolution.
- [ ] `CharacterController.is_position_valid()` cek: di dalam wall, di dalam objek solid, di spike aktif.
- [ ] Safe reposition: fade 0.3s, pindah ke anchor terdekat.
- [ ] Jika tidak ada anchor valid → reset level.
- [ ] Emit `SignalBus.safe_reposition_triggered`.

**Test:** Ciptakan kondisi invalid (surface hilang di bawah karakter inactive) → teleport ke anchor.

---

### [S4-03] PiP Test & Polish

**Ref:** Arsitektur §11
**Est:** 0.5 hari
**Deps:** S1-06
**DoD:**
- [ ] PiP border warna sesuai realita inactive.
- [ ] PiP tetap update saat switch (bukan follow character).
- [ ] Performa 60fps.

**Test:** Switch berulang, PiP selalu mirror kamera inactive.

---

### [S4-04] HintSystem + HintPanel

**Ref:** Level 1 Design §8; Arsitektur §12
**Est:** 1 hari
**Deps:** S4-01
**DoD:**
- [ ] `HintSystem` track waktu tanpa progres per level.
- [ ] Trigger tier 1 (30s), tier 2 (60s), tier 3 (90s).
- [ ] `HintPanel` menampilkan teks Echo-07.
- [ ] Teks hint per level disimpan sebagai data (`.json` atau `Resource`).
- [ ] Hint hilang saat progres terjadi.
- [ ] Setelah exit B tercapai di Level 1, hint nonaktif.

**Test:** Diam 30 detik di Level 1 → hint tier 1.

---

### [S4-05] Debug Overlay

**Ref:** Arsitektur §13
**Est:** 1 hari
**Deps:** S4-02
**DoD:**
- [ ] Panel toggle `F1`.
- [ ] Tampilkan: RealityManager state, cooldown, posisi + cell + facing + state karakter, level id, exit status, link states, delayed queue, last safe reposition.
- [ ] Update 10 Hz (bukan per frame).
- [ ] Tidak mengganggu gameplay.

**Test:** `F1` → overlay dengan data akurat.

---

### [S4-06] Regression Test Level 1–2 + Reset

**Est:** 0.5 hari
**Deps:** Semua Sprint 4
**DoD:**
- [ ] Level 1–2 tetap playable.
- [ ] Reset berfungsi di setiap titik.
- [ ] Safe reposition teruji 2 skenario.
- [ ] Tidak ada regression.

---

## 7. Fase 5 — Vertical Slice Level 3–4 (Sprint 5–6)

**Tujuan:** Level 3 (Delayed + OneWay) + Level 4 (Combine) playable.
**Ref:** Arsitektur §15 step 16–17.
**Estimasi:** 10–12 hari.

**Catatan:** Boss The Convergence **ditunda**; Level 4 di MVP adalah puzzle combine, bukan boss.

---

### Sprint 5 — Level 3 (Delayed + OneWay)

#### [S5-01] Link Type — Delayed

**Ref:** Mekanik v2.0 §3.6; Arsitektur §8.3
**Est:** 1 hari
**Deps:** S4-01
**DoD:**
- [ ] `DelayedEntry` queue di LinkResolver.
- [ ] Apply target setelah `delay` detik.
- [ ] Queue di-clear saat reset.
- [ ] Feedback countdown ring di target.

**Test:** Level 3 puzzle delayed.

---

#### [S5-02] Link Type — OneWay

**Ref:** Mekanik v2.0 §3.6
**Est:** 0.5 hari
**Deps:** S2-03
**DoD:**
- [ ] `ONE_WAY`: target berubah, tidak emit balik.
- [ ] Source tetap bisa berubah state.

**Test:** OneWay link tidak menyebabkan loop.

---

#### [S5-03] Button (One-shot)

**Ref:** Mekanik v2.0 §3.4
**Est:** 0.5 hari
**Deps:** S2-01
**DoD:**
- [ ] `Button extends InteractableBase`.
- [ ] Mode `one_shot` (MVP; timed ditunda).
- [ ] Feedback visual.

**Test:** Button ditekan sekali → permanen aktif sampai reset.

---

#### [S5-04] Level03 Greybox (Room 3A + Room 3B)

**Ref:** Level 3 Design (belum dibuat)
**Est:** 1.5 hari
**Deps:** S5-01, S5-02, S5-03
**DoD:**
- [ ] `Level03.tscn` dengan 2 room.
- [ ] Puzzle: button A → delayed door B (atau kombinasi delayed + oneway).
- [ ] ExitZone A dan B.
- [ ] Spike opsional.

**Test:** Level 3 selesai.

---

#### [S5-05] Integration Test Level 1–3

**Est:** 0.5 hari
**Deps:** S5-04
**DoD:**
- [ ] Level 1–3 berurutan playable.
- [ ] Delayed link teruji di playtest.
- [ ] OneWay link tidak menyebabkan loop.

---

### Sprint 6 — Level 4 (Combine)

#### [S6-01] Link Type — Mirror

**Ref:** Mekanik v2.0 §3.6
**Est:** 1 hari
**Deps:** S2-03
**DoD:**
- [ ] `MIRROR` dengan `mirror_mapping` dict eksplisit.
- [ ] Mapping harus lengkap; warn di editor jika tidak.
- [ ] Tidak menyebabkan loop.

**Test:** Mirror lever A → 2 door B berlawanan arah.

---

#### [S6-02] Link Type — Destructible

**Ref:** Mekanik v2.0 §3.6
**Est:** 1 hari
**Deps:** S4-01
**DoD:**
- [ ] `DESTRUCTIBLE`: one-shot sampai reset.
- [ ] Target hilang / disable permanen.
- [ ] Snapshot menyimpan state destructible.

**Test:** Wall hancur → surface hilang. Reset → kembali.

---

#### [S6-03] Lever

**Ref:** Mekanik v2.0 §3.4
**Est:** 0.5 hari
**Deps:** S2-01
**DoD:**
- [ ] `Lever extends InteractableBase`.
- [ ] Toggle on/off.
- [ ] Emit LinkRequest.

**Test:** Lever toggle → mirror link trigger.

---

#### [S6-04] Level04 Greybox (Room 4A + Room 4B)

**Ref:** Level 4 Design (belum dibuat); Combine semua mekanik
**Est:** 2 hari
**Deps:** S6-01, S6-02, S6-03
**DoD:**
- [ ] `Level04.tscn` dengan 2 room.
- [ ] Puzzle: combine minimal 3 link types (mis. push + offset + mirror, atau delayed + destructible + toggle).
- [ ] ExitZone A dan B.
- [ ] Spike + safe anchor.

**Test:** Level 4 selesai.

---

#### [S6-05] Vertical Slice Full Playthrough

**Ref:** Level 1–4 Design
**Est:** 0.5 hari
**Deps:** S6-04
**DoD:**
- [ ] Level 1–4 berurutan playable.
- [ ] Median playthrough 10–15 menit.
- [ ] Semua hint muncul kontekstual.
- [ ] Reset berfungsi di setiap level.
- [ ] Tidak ada softlock.
- [ ] Catat playtest lengkap.

---

## 8. Fase 6 — Polish (Sprint 7)

**Tujuan:** Layak untuk playtest eksternal.
**Estimasi:** 5–6 hari.

---

### [S7-01] Audio Placeholder

**Est:** 1 hari
**DoD:** SFX: switch, link, push, door, plate, spike, exit, hint. Music loop 2 menit.
**Test:** Setiap event ada bunyi.

---

### [S7-02] Visual Polish Greybox

**Est:** 2 hari
**DoD:**
- [ ] Tile warna final per realita (A=hangat, B=dingin).
- [ ] Sprite karakter top-down (placeholder 4 arah atau flip).
- [ ] Border PiP.
- [ ] Efek switch (flash + fade).
- [ ] Garis resonance antar link.

**Test:** Visual terbaca tanpa baca teks.

---

### [S7-03] Screen Shake + Hitstop Ringan

**Est:** 0.5 hari
**DoD:** Spike kill, destructible, safe reposition punya feedback berat.
**Test:** Terasa berbeda dari aksi ringan.

---

### [S7-04] Pause Menu + Settings Dasar

**Est:** 1 hari
**DoD:** Pause (`Esc`), resume, reset level, quit. Volume slider. Fullscreen toggle.
**Test:** Semua berfungsi.

---

### [S7-05] Playtest Eksternal — 5 Orang

**Est:** 1 hari (termasuk analisis)
**DoD:**
- [ ] 5 playtester menyelesaikan Level 1–4.
- [ ] Catat waktu per level, hint usage, kebingungan.
- [ ] Identifikasi 3 masalah utama.
- [ ] Buat `playtest_report.md`.

**Test:** Metrik tercapai: Level 1 median <75 dtk, Level 4 <180 dtk, hint usage <20%.

---

### [S7-06] Perbaikan dari Playtest

**Est:** 1 hari
**DoD:** Perbaiki 3 masalah utama, verifikasi ulang.

---

## 9. Ringkasan Sprint & Gate

| Sprint | Fokus | Est | Gate |
|---|---|---|---|
| 1 | Fondasi (4-dir, fixed camera, PiP mirror) | 5–6 hari | — |
| 2 | Gameloop Level 1 (2 room) | 6–7 hari | **Gate 1** |
| 3 | Push 4-dir + Level 2 | 6–7 hari | **Gate 2** |
| 4 | Robustness | 4–5 hari | — |
| 5 | Delayed + OneWay + Level 3 | 5–6 hari | — |
| 6 | Mirror + Destructible + Level 4 | 5–6 hari | — |
| 7 | Polish | 5–6 hari | **Prototype siap** |
| **Total** | — | **36–50 hari** | — |

---

## 10. Task Tracking Board

Kolom:

```text
Backlog | This Sprint | In Progress | Blocked | Review | Done
```

Aturan solo:

- Maksimal **2 task** di `In Progress`.
- Task pindah `Review` setelah DoD terpenuhi.
- Task pindah `Done` setelah playtest manual.
- `Blocked` wajib punya catatan alasan.

---

## 11. Risiko Eksekusi Solo (Top-Down)

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Kode "warisan" platformer (gravity, jump) | Bug halus | Verifikasi tidak ada `is_on_floor()` di semua script |
| Facing system tidak konsisten | Push salah arah | Test matrix 4-arah di S3-01 |
| Level design 2-room terlalu rumit | Over-scope | Kunci Level 1–2 dulu, playtest, baru Level 3–4 |
| Door delay close buggy | Karakter bisa clip | Unit test door edge case (S2-05) |
| PiP mirror salah kamera | Player bingung | Test switch berulang (S4-03) |
| Scope creep (mekanik baru) | Jadwal melar | Kunci: hanya yang ada di backlog |
| Burnout | Proyek berhenti | Sprint 5 hari + 1 hari istirahat |
| Lupa state setelah jeda | Waktu recall | Update `devlog.md` per sprint |
| Playtest terlambat | UX buruk akhir | Playtest Level 1 di Gate 1 |

---

## 12. Yang Ditunda (Di Luar Backlog Ini)

- **Boss The Convergence** — butuh Boss Design, target setelah prototype lulus.
- **Timed button** dan **multi-button door** — akan dibedah setelah Level 1–4 stabil.
- **Hazard tambahan** — pit, lava, laser.
- **Mekanik tambahan** — dash, grab/throw, echo pulse.
- **Narasi Echo-07 lengkap** — placeholder teks.
- **Art final** — sprite/sound greybox.
- **Save/load** — tidak relevan untuk prototype 15 menit.
- **Steam integration** — setelah prototype lulus.
- **Localization** — ditunda.
- **Accessibility penuh** — hanya basic (volume slider, fullscreen).

---

## 13. Roadmap Dokumen

| Langkah | Dokumen | Status |
|---|---|---|
| 1 | Spesifikasi Mekanik Formal v2.0 | Selesai |
| 2 | Level 1 Design | Selesai |
| 2b | Level 2–4 Design | Belum |
| 3 | Arsitektur Godot 4 v2.0 | Selesai |
| 4 | Boss Design Document | Belum (ditunda) |
| 5 | Prototype Backlog v2.0 | **Selesai (dokumen ini)** |

---

## 14. Langkah Berikutnya

Setelah dokumen ini:

1. **Mulai Sprint 1.** Kerjakan `[S1-01]` sampai `[S1-07]` sesuai urutan.
2. Update `devlog.md` setiap akhir sprint.
3. Sebelum Sprint 3, buat **Level 2 Design** (2 room: Room 2A + 2B) — bisa pakai template Level 1 Design.
4. Sebelum Sprint 5, buat **Level 3 Design**.
5. Sebelum Sprint 6, buat **Level 4 Design**.
6. Setelah Gate 2 lulus, pertimbangkan **Boss Design** sebagai dokumen paralel.

**Prioritas konten berikutnya:** Level 2 Design (Push + Offset) — dibutuhkan sebelum S3-05.