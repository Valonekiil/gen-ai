# Splitbound — Level 1 Design: "The First Fracture"

> **Status:** Draft v1.0 (Top-Down)
> **Level:** 1 dari 4
> **Total Room:** 2 (Room 1A = Reality A, Room 1B = Reality B)
> **Fungsi:** Introduce — switch, plate (character weight), toggle link
> **Terkait:** Mekanik Formal v2.0 (Langkah 1), Arsitektur Godot 4 (Langkah 3)

---

## 0. Definisi Level

| Istilah | Definisi |
|---|---|
| **Level** | Satu puzzle utuh = 2 room (A + B) yang saling terkait |
| **Room** | Satu layar realita. Kamera fixed. Ukuran 16×12 tile |
| **Room 1A** | Ruangan di Reality A |
| **Room 1B** | Ruangan di Reality B |

---

## 1. Spesifikasi Level 1

| Aspek | Nilai |
|---|---|
| Nama Level | "The First Fracture" |
| Fungsi Progresi | Introduce |
| Mekanik Baru | Switch, Plate (character weight), Toggle link |
| Mekanik Tidak Ada | Push, offset, mirror, one-way, delayed, destructible, spike, moving surface |
| Bahaya | Tidak ada |
| Estimasi Solve | 45–75 detik |
| Hint | 3 tier (30s / 60s / 90s) |
| Checkpoint | 2 (spawn A, spawn B) |
| Safe Anchor | 2 per room |
| Softlock Risk | Tidak (hanya perlu step off/on plate) |
| Reset | Manual (`R`) |

---

## 2. Legenda Grid

```
#  = wall (solid, tidak bisa dilewati)
.  = floor (walkable)
S  = spawn point karakter
E  = exit zone (Area2D)
P  = plate (momentary, aktif selama ada weight)
D  = door (toggle, controlled by link)
A  = safe anchor
```

Grid: **16 kolom × 12 baris** per room.
Tile size: **32×32 pixel**.
Room pixel size: **512×384 pixel**.
Kamera: **fixed**, mengunci seluruh room.

---

## 3. Room 1A — Reality A

### 3.1 Layout

```
Kolom:  0123456789012345
Baris 0: ################
Baris 1: #S.............#
Baris 2: #..............#
Baris 3: #....####......#
Baris 4: #....#..#......#
Baris 5: #....#..#......#
Baris 6: #....####......#
Baris 7: #..............#
Baris 8: #......P.......#
Baris 9: #..............#
Baris 10:#............E.#
Baris 11:################
```

### 3.2 Entitas

| Entitas | Posisi (row, col) | Tipe | Catatan |
|---|---|---|---|
| Spawn A | (1, 1) | Marker2D | Facing: down |
| Plate P | (8, 7) | Plate (momentary) | Aktif saat karakter atau pushable di atasnya |
| Exit E_A | (10, 14) | Area2D | Win condition untuk A |
| Safe Anchor A1 | (1, 1) | Marker2D | Di spawn |
| Safe Anchor A2 | (10, 1) | Marker2D | Pojok kiri bawah |

### 3.3 Path Analysis

A dapat bergerak bebas dari spawn ke plate dan ke exit. Tidak ada door atau penghalang.

- Path ke plate: `(1,1) → (1,7) → (7,7) → (8,7)`
- Path dari plate ke exit: `(8,7) → (9,7) → (10,7) → (10,14)`

Pillar di baris 3–6, kolom 5–8 adalah obstacle visual; tidak menghalangi path karena ada celah di semua sisi.

### 3.4 Kamera

- `CameraA.position = (256, 192)` (center room)
- `CameraA.limit_left = 0`
- `CameraA.limit_right = 512`
- `CameraA.limit_top = 0`
- `CameraA.limit_bottom = 384`
- `CameraA.zoom = Vector2(1.0, 1.0)` (asumsi viewport 512×384)
- Smoothing: **disabled** (fixed camera)

---

## 4. Room 1B — Reality B

### 4.1 Layout

```
Kolom:  0123456789012345
Baris 0: ################
Baris 1: #S.............#
Baris 2: #..............#
Baris 3: ########D#######
Baris 4: #..............#
Baris 5: #..............#
Baris 6: #..............#
Baris 7: #..............#
Baris 8: #..............#
Baris 9: #..............#
Baris 10:#............E.#
Baris 11:################
```

### 4.2 Entitas

| Entitas | Posisi (row, col) | Tipe | Catatan |
|---|---|---|---|
| Spawn B | (1, 1) | Marker2D | Facing: down |
| Door D_B | (3, 8) | Door (toggle) | Controlled by Plate P in Room 1A |
| Exit E_B | (10, 14) | Area2D | Win condition untuk B |
| Safe Anchor B1 | (1, 1) | Marker2D | Di spawn |
| Safe Anchor B2 | (1, 14) | Marker2D | Pojok kanan atas |

### 4.3 Path Analysis

B harus melewati door D_B untuk mencapai exit. Dinding baris 3 menutup seluruh jalur horizontal.

- Path ke door: `(1,1) → (2,1) → (2,8) → (3,8)`
- Path dari door ke exit: `(3,8) → (10,8) → (10,14)`

Jika D_B tertutup, B terhalang di (2,8) — tidak bisa ke bawah.

### 4.4 Kamera

- `CameraB.position = (10256, 192)` (center Room B, offset +10000)
- `CameraB.limit_left = 10000`
- `CameraB.limit_right = 10512`
- `CameraB.limit_top = 0`
- `CameraB.limit_bottom = 384`
- `CameraB.zoom = Vector2(1.0, 1.0)`
- Smoothing: **disabled**

**Catatan:** Offset +10000 di X memisahkan Reality A dan Reality B di world space. Lihat Arsitektur Godot 4 §0.

---

## 5. Link Configuration

### 5.1 RealityLink

| Field | Nilai |
|---|---|
| `id` | `link_plate_to_door` |
| `source_id` | `plate_1a` |
| `target_id` | `door_1b` |
| `type` | `TOGGLE` |
| `delay` | `0.0` |
| `one_shot` | `false` |
| `condition` | `""` |

**Semantik:**
- Plate `pressed` (ada weight) → Door `open`.
- Plate `released` (tidak ada weight) → Door `closed`.

### 5.2 Weight Sources untuk Plate

Plate di Room 1A aktif jika salah satu kondisi terpenuhi:

1. Karakter A berdiri di atasnya (aktif maupun inactive).
2. Pushable block di atasnya (tidak dipakai di Level 1, tapi spec mendukung).

---

## 6. Solusi Puzzle

### 6.1 Urutan Solusi yang Diharapkan

```text
1. Pemain mulai sebagai A.
2. A berjalan dari spawn ke plate P di (8,7).
3. A berdiri di plate → Door B terbuka.
   (PiP menunjukkan pintu B membuka.)
4. Pemain switch ke B (Tab/Q).
   A menjadi inactive, tetap berdiri di plate → plate tetap pressed.
5. B berjalan dari spawn ke door D_B, melewatinya, ke exit E_B.
6. B mencapai exit E_B. Win condition B = terpenuhi.
7. Pemain switch ke A.
8. A melangkah dari plate → Door B menutup.
   (B sudah di exit, aman.)
9. A berjalan dari plate ke exit E_A.
10. A mencapai exit E_A. Win condition A = terpenuhi.
11. Room 1 selesai. Transisi ke Level 2 (Room 2A + 2B).
```

### 6.2 Diagram Alur

```
[Aktif A]
   │
   ├─ A jalan ke plate
   ├─ A berdiri di plate → Door B OPEN
   │
   ▼
[Switch ke B]
   │
   ├─ A inactive di plate (plate tetap pressed)
   ├─ B jalan → lewat door → exit B
   │
   ▼
[Switch ke A]
   │
   ├─ A step off plate → Door B CLOSE
   ├─ A jalan ke exit A
   │
   ▼
[Kedua karakter di exit] → LEVEL COMPLETE
```

### 6.3 Kunci Puzzle

**Tension inti:** A tidak bisa berada di dua tempat sekaligus.

- A harus berdiri di plate agar B bisa lewat.
- A juga harus ke exit agar menang.
- Solusi: A **tetap** di plate selama B lewat, **baru** bergerak ke exit setelah B aman.

Ini mengajarkan pemain konsep **inactive character tetap berinteraksi dengan dunia** (plate tetap pressed oleh A yang inactive).

---

## 7. Failure Modes & Recovery

| Skenario | Dampak | Recovery |
|---|---|---|
| A melangkah dari plate sebelum switch ke B | Door B tertutup, B tidak bisa lewat | A berdiri kembali di plate, lalu switch |
| A melangkah dari plate saat B sedang di pintu | Door B tidak menutup (B di tile pintu) | B lanjut lewat, lalu A langkah penuh |
| A melangkah dari plate setelah B lewat tapi B belum di exit | Door B tertutup, tapi B sudah di sisi lain | B lanjut ke exit, aman |
| Player reset (`R`) kapan saja | Room kembali ke snapshot awal | Main ulang |

**Tidak ada softlock** di Level 1. Pemain selalu bisa reset atau ulangi aksi.

### 7.1 Aturan Door Menutup dengan Karakter di Tile-nya

Jika door menerima sinyal `close` tapi ada karakter di tile door:

1. Door **menunda** penutupan sampai tile kosong.
2. Door tetap `open` secara visual sampai tile kosong.
3. Setelah tile kosong, door menutup dalam 0,15 detik.

Ini mencegah clipping.

---

## 8. Hint Echo-07

| Tier | Trigger | Isi |
|---|---|---|
| 1 | 30 dtk tanpa progres | "Realita B merespons tindakanmu di A." |
| 2 | 60 dtk tanpa progres | "Pelat di A membuka pintu di B." |
| 3 | 90 dtk tanpa progres | "Tinggalkan A di atas pelat, lalu switch ke B." |

**Definisi progres:** setiap kali karakter aktif berpindah ≥3 tile dari posisi terakhir hint trigger, timer reset.

**Setelah player berhasil di B (B mencapai exit):** hint dinonaktifkan untuk room ini.

---

## 9. Visual Design (Minimal Art)

### 9.1 Palet Warna

| Entitas | Reality A | Reality B |
|---|---|---|
| Floor | `#E8C87A` (hangat, kuning pucat) | `#7A9CC8` (dingin, biru pucat) |
| Wall | `#8B5A2B` (coklat kayu) | `#2B3F8B` (biru tua) |
| Character | `#FFFFFF` (putih) dengan outline `#FF6B35` | `#FFFFFF` (putih) dengan outline `#35A8FF` |
| Plate (idle) | `#C84A4A` (merah tua) | — |
| Plate (pressed) | `#4AC84A` (hijau) | — |
| Door (closed) | — | `#8B5A2B` (coklat) |
| Door (open) | — | Transparan dengan outline |
| Exit | `#FFD700` (emas) | `#FFD700` (emas) |

### 9.2 Visual Switch

- Saat switch, realita aktif mendapat **saturasi penuh**; realita inactive mendapat **desaturasi 60%** + overlay warna.
- Border PiP berubah sesuai warna realita inactive.
- Karakter inactive mendapat **outline tipis** agar tetap terlihat.

### 9.3 PiP

- Ukuran: **320×240** (rasio 4:3, sesuai room 16×12).
- Posisi: pojok kanan atas, margin 16px dari tepi.
- Border: 3px, warna sesuai realita.
- Isi: render full room realita inactive (kamera fixed, tidak follow karakter).

**Catatan:** Karena kamera fixed per room, PiP tidak perlu follow karakter. Cukup render kamera realita inactive.

---

## 10. Audio (Placeholder)

| Event | SFX |
|---|---|
| Switch | Whoosh 0,2s + hum konstan |
| Plate pressed | Click + hum naik |
| Plate released | Click + hum turun |
| Door open | Creak 0,3s |
| Door close | Thud 0,15s |
| A melangkah | Footstep ringan |
| B melangkah | Footstep ringan (pitch berbeda) |
| Exit reached | Chime |
| Room complete | Fanfare pendek |

Music: **loop ambient rendah** di kedua room, crossfade saat switch (2 detik).

---

## 11. Acceptance Criteria

### 11.1 Fungsional

- [ ] A dapat berjalan 4-arah di Room 1A.
- [ ] B dapat berjalan 4-arah di Room 1B.
- [ ] Switch (`Tab`/`Q`) berfungsi antara A dan B.
- [ ] Plate terdeteksi saat A berdiri di atasnya.
- [ ] Plate **tetap pressed** saat A menjadi inactive (setelah switch).
- [ ] Door B terbuka saat plate pressed.
- [ ] Door B tertutup saat plate released.
- [ ] Door tidak menutup jika ada karakter di tile-nya.
- [ ] B dapat melewati door menuju exit.
- [ ] A dapat mencapai exit setelah B aman.
- [ ] Level complete saat kedua karakter di exit.
- [ ] Reset (`R`) mengembalikan room ke snapshot awal.
- [ ] Hint muncul di 30s/60s/90s.

### 11.2 UX

- [ ] Pemain dapat menjelaskan hubungan plate A → door B setelah solve (via think-aloud playtest).
- [ ] Median solve time <75 detik.
- [ ] Median reset count ≤1.
- [ ] Hint usage <30% (Level 1 sengaja mudah).
- [ ] Tidak ada kebingungan realita aktif (pemain tidak salah switch).

### 11.3 Teknis

- [ ] 60 FPS di build debug.
- [ ] Tidak ada error/warning di console.
- [ ] Debug overlay menampilkan state dengan benar.
- [ ] Snapshot restore 100% akurat (posisi, state plate, state door, realita aktif).

---

## 12. Metrik Playtest

| Metrik | Target | Cara Ukur |
|---|---|---|
| Solve time | <75 dtk | Timer dari load room sampai room_completed |
| Switch count | 2–3 | Log setiap `character_switched` |
| Reset count | ≤1 | Log setiap `room_reset` |
| Hint usage | <30% | Log setiap `hint_requested` |
| Player confusion | <30 dtk | Think-aloud recording |
| Enjoyment | ≥3/5 | Post-playtest survey |

---

## 13. Catatan Implementasi

1. **Plate harus mendeteksi inactive character.** Gunakan `Area2D` dengan layer collision yang mencakup kedua karakter. Jangan filter by `active` state.
2. **Door menunda penutupan jika ada karakter di tile-nya.** Cek `Area2D` sebelum menutup; jika terisi, queue close sampai kosong.
3. **Kamera fixed** — jangan tambah smoothing. Set posisi ke center room saat `_ready()`.
4. **PiP render kamera realita inactive** — jangan follow karakter. Cukup set `PiPCamera` ke posisi kamera realita inactive.
5. **Desaturasi realita inactive** — gunakan `CanvasModulate` atau shader global. Jangan ubah sprite satu per satu.
6. **Snapshot** harus menyimpan: posisi A, posisi B, state plate, state door, realita aktif. Queue link kosong (tidak ada delayed link di Level 1).
7. **Tidak ada gravity/jump** — jangan tambahkan `is_on_floor()` atau `gravity` di CharacterController.

---

## 14. Roadmap Level

| Level | Nama | Mekanik Baru | Status |
|---|---|---|---|
| 1 | The First Fracture | Switch, Plate, Toggle | **Selesai (dokumen ini)** |
| 2 | Displaced Weight | Push, Offset | Belum |
| 3 | Echoes of Delay | Delayed, OneWay | Belum |
| 4 | The Convergence | Combine (semua) | Belum |

**Catatan:** Progresi mekanik akan disesuaikan setelah Level 1 playtest. Jika Level 1 terlalu mudah, mekanik tambahan bisa dimajukan.

---

## 15. Yang Ditunda

Tidak termasuk di Level 1 (akan dibedah setelah playtest):

- Pushable block sebagai weight source (ada di spec, tidak dipakai di Level 1)
- Timed button
- Multi-button door
- Spike
- Moving surface
- Mirror link
- Destructible link
- Safe reposition trigger (tidak ada hazard, jadi tidak pernah terpicu)

---

## 16. Next Step

Setelah Level 1 di-review:

1. Playtest mental dengan layout di atas — cek apakah path dan puzzle masuk akal.
2. Jika setuju, saya bisa lanjut ke **Level 2 (Room 2A + Room 2B)** dengan mekanik **Push + Offset**.
3. Setelah Level 1–2 selesai, baru update **Arsitektur Godot 4** dan **Backlog** untuk top-down.