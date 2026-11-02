# Splitbound — Level 2 Design: "Displaced Weight"

> **Status:** Draft v1.0 (Top-Down)
> **Level:** 2 dari 4
> **Total Room:** 2 (Room 2A = Reality A, Room 2B = Reality B)
> **Fungsi:** Introduce — push 4-arah, offset link
> **Terkait:** Mekanik Formal v2.0 (Langkah 1), Level 1 Design, Arsitektur Godot v2.0 (Langkah 3)

---

## 0. Definisi Level

| Istilah | Definisi |
|---|---|
| **Level** | Satu puzzle utuh = 2 room (A + B) yang saling terkait |
| **Room** | Satu layar realita. Kamera fixed. Ukuran 16×12 tile |
| **Room 2A** | Ruangan di Reality A |
| **Room 2B** | Ruangan di Reality B |

---

## 1. Spesifikasi Level 2

| Aspek | Nilai |
|---|---|
| Nama Level | "Displaced Weight" |
| Fungsi Progresi | Introduce |
| Mekanik Baru | Push (4-arah), Offset link |
| Mekanik Carry-over | Switch, Plate, Toggle (dari Level 1, tidak dipakai di Level 2) |
| Bahaya | Tidak ada (spike diperkenalkan di Level 3) |
| Estimasi Solve | 60–90 detik |
| Hint | 3 tier (40s / 70s / 100s) — sedikit lebih longgar karena push butuh eksplorasi |
| Checkpoint | 2 (spawn A, spawn B) |
| Safe Anchor | 2 per room |
| Softlock Risk | Tidak |
| Reset | Manual (`R`) |

**Catatan pacing:** Level 2 fokus pada **satu mekanik besar**: push + offset. Spike dan hazard ditunda ke Level 3 agar Level 2 tetap clean sebagai "introduce".

---

## 2. Legenda Grid

```
#  = wall (solid)
.  = floor (walkable)
S  = spawn point karakter
E  = exit zone (Area2D)
C  = crate (pushable, 4-arah)
G  = gate (moving surface, controlled by offset link)
A  = safe anchor
```

Grid: **16 kolom × 12 baris** per room.
Tile size: **32×32 pixel**.
Room pixel size: **512×384 pixel**.
Kamera: **fixed**, mengunci seluruh room.

---

## 3. Room 2A — Reality A

### 3.1 Layout

```
Kolom:  0123456789012345
Baris 0: ################
Baris 1: #S.............#
Baris 2: #..............#
Baris 3: #..............#
Baris 4: #..............#
Baris 5: #....C.........#
Baris 6: #..............#
Baris 7: #..............#
Baris 8: #..............#
Baris 9: #..............#
Baris 10:#...........E..#
Baris 11:################
```

### 3.2 Entitas

| Entitas | Posisi (row, col) | Tipe | Catatan |
|---|---|---|---|
| Spawn A | (1, 1) | Marker2D | Facing: down |
| Crate C | (5, 5) | PushableObject | Posisi awal |
| Exit E_A | (10, 12) | Area2D | Win condition untuk A |
| Safe Anchor A1 | (1, 1) | Marker2D | Di spawn |
| Safe Anchor A2 | (10, 1) | Marker2D | Pojok kiri bawah |

### 3.3 Path Analysis

Room 2A **terbuka** — tidak ada wall internal. A bisa bergerak bebas.

- Path ke crate: `(1,1) → (5,5)` — bebas
- Posisi untuk push right: A di `(5,4)` facing right, crate di `(5,5)`
- Posisi untuk push left: A di `(5,6)` facing left, crate di `(5,5)`
- Path ke exit: `(1,1) → (10,12)` — bebas, bisa langsung

**Konsekuensi desain:** A **bisa** langsung ke exit tanpa push crate. Tapi jika begitu, B tidak bisa solve. Ini mengajarkan pemain bahwa **aksi A memengaruhi B**, dan urutan aksi penting.

### 3.4 Kamera

- `CameraA.position = (256, 192)`
- `limit_left/right/top/bottom = 0/512/0/384`
- Smoothing: **disabled**

---

## 4. Room 2B — Reality B

### 4.1 Layout

```
Kolom:  0123456789012345
Baris 0: ################
Baris 1: #S.............#
Baris 2: #..............#
Baris 3: #####.##########
Baris 4: #..............#
Baris 5: #..............#
Baris 6: #..............#
Baris 7: ##########.#####
Baris 8: #..............#
Baris 9: #..............#
Baris 10:#...........E..#
Baris 11:################
```

### 4.2 Entitas

| Entitas | Posisi (row, col) | Tipe | Catatan |
|---|---|---|---|
| Spawn B | (1, 1) | Marker2D | Facing: down |
| Gap 1 | (3, 5) | Tile kosong di wall row 3 | Harus dilewati B |
| Gap 2 | (7, 10) | Tile kosong di wall row 7 | Harus dilewati B |
| Gate G | (3, 5) | MovingSurface | Menutup Gap 1. **Posisi awal** |
| Exit E_B | (10, 12) | Area2D | Win condition untuk B |
| Safe Anchor B1 | (1, 1) | Marker2D | Di spawn |
| Safe Anchor B2 | (1, 14) | Marker2D | Pojok kanan atas |

### 4.3 Topologi Room

Room 2B dibagi dua oleh dinding horizontal:

- **Area Atas:** baris 1–2 (di atas wall row 3).
- **Area Tengah:** baris 4–6 (antara wall row 3 dan wall row 7).
- **Area Bawah:** baris 8–10 (di bawah wall row 7).

B harus menyeberang dari atas → tengah → bawah melalui 2 gap:

1. **Gap 1** di `(3, 5)` — di wall row 3.
2. **Gap 2** di `(7, 10)` — di wall row 7.

**Gap 2 selalu terbuka.** **Gap 1 diblokir oleh Gate G** yang diposisikan di tile gap.

### 4.4 Path Analysis

B tanpa bantuan A (gate di posisi awal):

- B dari spawn `(1,1)` hanya bisa bergerak di area atas (baris 1–2).
- Tidak bisa turun melewati wall row 3 karena Gap 1 terblokir Gate.
- **Stuck.**

B dengan bantuan A (gate dipindah):

- B dari `(1,1) → (2,5) → (3,5)` [Gap 1, gate sudah pindah] `→ (4,5) → (5,10) → (6,10) → (7,10)` [Gap 2, selalu terbuka] `→ (8,10) → (9,10) → (10,10) → (10,12)` = Exit.

### 4.5 Kamera

- `CameraB.position = (10256, 192)`
- `limit_left/right/top/bottom = 10000/10512/0/384`
- Smoothing: **disabled**

---

## 5. Link Configuration

### 5.1 RealityLink

| Field | Nilai |
|---|---|
| `id` | `link_crate_to_gate` |
| `source_id` | `crate_2a` |
| `target_id` | `gate_2b` |
| `type` | `OFFSET` |
| `delay` | `0.0` |
| `one_shot` | `false` |
| `offset_direction` | `Vector2i(1, 0)` |
| `condition` | `""` |

**Semantik offset_direction = (1, 0):**

- Ketika crate bergerak +1 tile di X (kanan), gate bergerak +1 tile di X (kanan).
- Ketika crate bergerak -1 tile di X (kiri), gate bergerak -1 tile di X (kiri).
- Ketika crate bergerak di Y (atas/bawah), gate **tidak bergerak**.

**Konsekuensi:** hanya push horizontal (kanan atau kiri) yang memengaruhi gate. Push vertikal tidak berpengaruh.

### 5.2 Aturan Offset

Dari Mekanik v2.0 §3.6:

1. Source bergerak Δ → target bergerak Δ (sesuai `offset_direction`).
2. Jika target cell blocked (di luar room, wall, atau ada objek solid) → **source rollback**.
3. Rollback artinya crate kembali ke posisi semula dan push dianggap gagal.

**Contoh edge case:**

- A push crate right 2x → gate dari (3,5) ke (3,7). Aman (di dalam wall, tapi wall tidak memblokir karena gate override).
- A push crate right sampai gate keluar room → **rollback** push terakhir. Crate tetap di posisi sebelumnya.

**Catatan desain:** gate boleh "berada di tile wall" secara visual (menyatu dengan wall). Collision gate yang aktif, wall di belakang gate tidak relevan.

---

## 6. Solusi Puzzle

### 6.1 Urutan Solusi yang Diharapkan

```text
1. Pemain mulai sebagai A.
2. A berjalan ke posisi push: (5, 4), menghadap kanan.
3. A tekan E → crate bergeser dari (5,5) ke (5,6).
   Gate B bergeser dari (3,5) ke (3,6).
   Gap 1 di (3,5) sekarang terbuka (gate pindah ke wall col 6).
4. A berjalan ke exit E_A di (10, 12).
5. Pemain switch ke B (Tab/Q).
6. B berjalan: (1,1) → (2,5) → (3,5) [Gap 1] → (4,5) → (5,10) → (6,10) → (7,10) [Gap 2] → (8,10) → (9,10) → (10,10) → (10,12) = Exit.
7. B mencapai exit. Level complete.
```

### 6.2 Alternatif Solusi

**Alternatif 1: A push crate left (1x)**

1. A ke (5,6), push crate left → crate ke (5,4), gate ke (3,4).
2. Gate di (3,4) = wall position. Gap 1 di (3,5) terbuka.
3. Solusi tetap valid.

**Alternatif 2: A push crate right 2x**

1. A push crate right 2x → crate ke (5,7), gate ke (3,7) = wall position.
2. Gap 1 di (3,5) tetap terbuka.
3. Solusi valid.

**Kesimpulan:** Level 2 **tidak memaksa solusi tunggal** — beberapa push valid asalkan gate keluar dari Gap 1. Ini sengaja — Level 2 adalah **introduce**, bukan puzzle ketat.

### 6.3 Diagram Alur

```
[Aktif A]
   │
   ├─ A ke (5,4), push crate right
   ├─ Gate B pindah dari Gap 1
   │
   ▼
[A jalan ke exit E_A]
   │
   ├─ A standing di exit
   │
   ▼
[Switch ke B]
   │
   ├─ B jalan lewat Gap 1
   ├─ B jalan lewat Gap 2
   ├─ B ke exit E_B
   │
   ▼
[Kedua karakter di exit] → LEVEL COMPLETE
```

### 6.4 Urutan Kesalahan yang Umum (Diharapkan)

| Kesalahan | Efek | Recovery |
|---|---|---|
| A langsung ke exit tanpa push crate | B stuck di area atas | A push crate (A masih bisa bergerak dari exit) |
| A push crate DOWN | Crate bergeser ke (6,5), gate tidak bergerak | Player menyadari push vertikal tidak berpengaruh, coba arah lain |
| A push crate UP | Crate bergeser ke (4,5), gate tidak bergerak | Sama |
| A push crate RIGHT 4x sampai gate keluar room | Rollback (push terakhir ditolak) | A push ke arah lain atau balik |
| A push crate LEFT sampai gate di (3,2) | Gap 1 di (3,5) tetap terbuka | Solusi valid |
| B jalan ke Gap 2 duluan sebelum Gap 1 terbuka | B stuck di area atas | B kembali ke spawn, tunggu A push crate |
| B di Gap 1 saat A push crate yang menutup gate | Gate menutup di posisi B → Safe Reposition B | B ke anchor terdekat |

**Tidak ada softlock** di Level 2. Semua kesalahan recoverable.

---

## 7. Failure Modes & Recovery

| Skenario | Dampak | Recovery |
|---|---|---|
| A push crate ke arah yang tidak memengaruhi gate | Gap 1 tetap tertutup | Push crate ke arah yang benar (horizontal) |
| Crate terhalang oleh wall (tidak bisa push) | Crate stuck | Push crate arah lain; crate tidak pernah kehilangan mobility karena room terbuka |
| Gate di posisi wall yang menghalangi B | B tidak bisa lewat | A push crate untuk memindahkan gate |
| A push crate terlalu jauh sampai rollback | Crate tidak bergerak | A push ke arah lain |
| B di Gap 1 saat gate menutup | B **Safe Reposition** ke anchor terdekat | Otomatis; tidak reset room |
| Player reset (`R`) | Room kembali ke snapshot | Main ulang |

**Tidak ada death.** Tidak ada softlock.

### 7.1 Gate Menutup dengan Karakter di Tile-nya

Jika A push crate sehingga gate kembali ke Gap 1 dan B sedang di tile (3,5):

1. `LinkResolver` mendeteksi gate akan menutup posisi B.
2. Sebelum gate move, cek apakah tile tujuan gate kosong dari karakter.
3. Jika ada karakter → **gate menunda close** sampai tile kosong.
4. Jika tile sudah lama tidak kosong (B diam di sana) → **Safe Reposition B** ke anchor terdekat, lalu gate close.

Prioritas: menjaga B tetap valid > menyelesaikan link.

**Catatan:** B kemungkinan besar tidak diam di Gap 1 karena sudah lewat. Kasus ini jarang tapi harus ditangani.

---

## 8. Hint Echo-07

| Tier | Trigger | Isi |
|---|---|---|
| 1 | 40 dtk tanpa progres | "B tidak bisa melewati dinding di Realita B." |
| 2 | 70 dtk tanpa progres | "Kotak di A bergema ke gerbang di B." |
| 3 | 100 dtk tanpa progres | "Dorong kotak ke kanan agar gerbang B bergeser dari celah." |

**Definisi progres:** karakter aktif berpindah ≥3 tile dari posisi hint trigger terakhir.

**Setelah B mencapai exit:** hint nonaktif untuk level ini.

---

## 9. Visual Design (Minimal Art)

### 9.1 Palet Warna

| Entitas | Reality A | Reality B |
|---|---|---|
| Floor | `#E8C87A` (hangat) | `#7A9CC8` (dingin) |
| Wall | `#8B5A2B` | `#2B3F8B` |
| Character | Putih + outline `#FF6B35` | Putih + outline `#35A8FF` |
| Crate C | `#A0522D` (coklat tua) dengan border `#3E2723` | — |
| Gate G | — | `#FFB300` (oranye terang) — kontras dengan wall biru |
| Exit | `#FFD700` | `#FFD700` |

**Catatan gate:** karena gate bisa berada di atas wall (visual menyatu), beri gate warna yang **kontras dengan wall** agar pemain selalu bisa melihat posisi gate. Atau gunakan outline putih.

### 9.2 Visual Switch

- Realita aktif: saturasi penuh.
- Realita inactive: desaturasi 60% + tint.
- PiP realita inactive render full room.
- Karakter inactive outline tipis.

### 9.3 Efek Offset Link

Saat crate bergerak dan gate bergerak akibat offset:

- Garis resonance (tipis, 1 detik) dari crate ke gate, melewati batas realita.
- Flash kecil di gate saat tiba di posisi baru.
- Audio: "whoosh" crate + "click" gate.

Ini **penting** — pemain harus sadar gate bergerak akibat crate, bukan kebetulan.

---

## 10. Audio (Placeholder)

| Event | SFX |
|---|---|
| Push crate | Grind ringan 0,15s |
| Push blocked | Buzz |
| Gate bergerak | Click + slide |
| Gate berhenti | Thud halus |
| Offset link trigger | Whoosh + tick |
| Exit reached | Chime |
| Level complete | Fanfare |

Music: loop ambient, sama seperti Level 1.

---

## 11. Acceptance Criteria

### 11.1 Fungsional

- [ ] A dapat push crate 4-arah di Room 2A.
- [ ] Push crate horizontal → gate B bergerak sesuai offset.
- [ ] Push crate vertikal → gate B **tidak** bergerak.
- [ ] Gate B bergerak ke posisi wall → gap di (3,5) terbuka.
- [ ] B dapat melewati Gap 1 dan Gap 2 menuju exit.
- [ ] A dapat mencapai exit tanpa push crate (tidak softlock).
- [ ] Safe Reposition terpicu jika gate menutup di posisi B.
- [ ] Reset (`R`) mengembalikan crate, gate, dan kedua karakter ke snapshot.
- [ ] Hint muncul di 40s/70s/100s.

### 11.2 UX

- [ ] Pemain mendorong crate sebelum switch ke B (dalam ≥80% playtest).
- [ ] Pemain menyadari push vertikal tidak memengaruhi gate setelah 1–2 percobaan.
- [ ] Median solve time <90 detik.
- [ ] Hint usage <40%.
- [ ] Player tidak bingung realita aktif.

### 11.3 Teknis

- [ ] 60 FPS di build debug.
- [ ] Tidak ada error/warning.
- [ ] Debug overlay menampilkan state crate dan gate dengan benar.
- [ ] Snapshot restore 100% akurat.

---

## 12. Metrik Playtest

| Metrik | Target | Cara Ukur |
|---|---|---|
| Solve time | <90 dtk | Timer level_completed |
| Push count | 1–4 | Log push berhasil |
| Push blocked count | 0–2 | Log push rollback/ditolak |
| Switch count | 1–3 | Log character_switched |
| Reset count | ≤1 | Log room_reset |
| Hint usage | <40% | Log hint_requested |
| Push direction confusion | <1 percobaan | Log push direction vs target |
| Enjoyment | ≥3/5 | Post-playtest survey |

---

## 13. Catatan Implementasi

1. **Gate adalah `MovingSurface`** yang di-link via `OFFSET`. Implementasi di S3-03 (MovingSurface) dan S3-02 (Offset).
2. **Offset direction `(1,0)`** berarti gate hanya bergerak horizontal. Push vertikal crate tidak memicu gate. Verifikasi di unit test.
3. **Gate di atas wall** — pastikan render gate di z-index lebih tinggi dari wall, atau gunakan outline. Collision gate override wall collision saat gate berada di tile wall (wall di belakang gate di-disable collision-nya).
4. **Rollback** saat gate keluar room — penting untuk mencegah error.
5. **Safe Reposition B** jika gate menutup posisi B — implementasi di S4-02, tapi edge case harus sudah terdeteksi di S3-02.
6. **Tidak ada spike** di Level 2 — spike script (S3-04) diimplementasikan tapi tidak dipakai di layout. Spike pertama muncul di Level 3.
7. **Kamera fixed** — jangan tambah smoothing.
8. **PiP render full room B** saat A aktif (dan sebaliknya).
9. **Snapshot** menyimpan: posisi A, posisi B, facing A, facing B, posisi crate, posisi gate, realita aktif.

---

## 14. Roadmap Level

| Level | Nama | Mekanik Baru | Status |
|---|---|---|---|
| 1 | The First Fracture | Switch, Plate, Toggle | Selesai |
| 2 | Displaced Weight | Push 4-arah, Offset | **Selesai (dokumen ini)** |
| 3 | Echoes of Delay | Delayed, OneWay, Spike | Belum |
| 4 | The Convergence | Mirror, Destructible, Lever, Combine | Belum |

---

## 15. Yang Ditunda dari Level 2

Tidak termasuk di Level 2 (akan diperkenalkan di Level 3 atau 4):

- Spike (Level 3)
- Delayed link (Level 3)
- OneWay link (Level 3)
- Mirror link (Level 4)
- Destructible link (Level 4)
- Lever (Level 4)
- Plate + crate combo (Level 3 — push crate ke plate agar plate permanen aktif)
- Timed button
- Multi-button door
- Boss encounter

---

## 16. Next Step

Setelah Level 2 di-review:

1. Review mental — cek apakah path A dan B masuk akal.
2. Setuju → saya bisa lanjut ke **Level 3 Design (Room 3A + Room 3B)** dengan mekanik **Delayed + OneWay + Spike**.
3. Setelah Level 3–4 selesai, vertical slice konten lengkap.

**Catatan untuk Sprint 3:** Sebelum S3-05 (Level 2 Greybox), dokumen ini harus sudah di-review. Setelah itu, Level 2 Design ini bisa dijadikan acuan wiring langsung.