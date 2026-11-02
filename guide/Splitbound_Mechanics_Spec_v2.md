# Splitbound — Spesifikasi Mekanik Formal (v2.0 Top-Down)

> **Status:** Draft v2.0
> **Ruang Lingkup:** Spesifikasi mekanik inti untuk prototype
> **Perubahan dari v1.0:** Pivot dari puzzle-platformer ke top-down puzzle adventure
> **Terkait:** GDD Splitbound, Langkah 2 (Level Design), Langkah 3 (Arsitektur)

---

## 0. Perubahan dari v1.0

| Aspek | v1.0 (Platformer) | v2.0 (Top-Down) |
|---|---|---|
| Genre | Puzzle Platformer | Top-Down Puzzle Adventure |
| Movement | Horizontal + jump + gravity | 4-directional, tanpa gravity |
| Jump | Ada (Space) | **Dihapus** |
| Pengganti jump | — | **Push box + Activate button** (fokus puzzle) |
| Push/Pull | Horizontal saja | **4-directional** |
| Moving Platform | Vertikal (lift) | **Moving Surface** (bridge, block, floor tile) |
| Hazard utama | Spike pit, fall | **Spike tile** (floor, tanpa pit) |
| Camera | Follow horizontal | **Fixed per room** (1 room = 1 layar) |
| Perspektif | Side-view | Pure top-down |

**Yang TIDAK berubah:**

- USP dual-reality switching
- Semua 6 link types (Toggle, Offset, Mirror, OneWay, Delayed, Destructible)
- Switch, safe reposition, reset, snapshot
- Realita A/B di-offset spasial
- Echo-07, The Convergence
- Data structures (`RealityLink`, `RoomSnapshot`, `ResonanceEvent`)

**Ditunda (akan dibedah di iterasi berikut):**

- Tombol timer (timed button)
- Pintu dengan banyak tombol (multi-button door)
- Pit / lava / laser hazard
- Dash / roll / dodge

---

## 1. Glossary & Invariants

| Istilah | Definisi |
|---|---|
| Realita A / B | Dua dunia paralel yang berjalan di room yang sama, di-offset spasial. |
| Karakter A / B | Dua versi The Explorer. Hanya satu menerima input. |
| Active Character | Karakter yang sedang dikendalikan pemain. |
| Inactive Character | Karakter yang tidak menerima input, tetapi tetap ada di dunia. |
| Link / Resonance | Hubungan antara objek di Realita A dan B. |
| Source Object | Objek yang memicu perubahan. |
| Target Object | Objek yang berubah akibat link. |
| Safe Anchor | Titik aman untuk reposition karakter tidak aktif. |
| Room Snapshot | State awal room untuk reset. |
| Desync | Kondisi ketika posisi/state karakter tidak valid akibat perubahan link. |
| Moving Surface | Objek yang bergerak (bridge, block, floor tile) dan membawa karakter di atasnya. |
| Plate | Tombol lantai yang aktif selama ada weight (karakter atau pushable). |
| Spike | Hazard lantai. Karakter mati saat menyentuh saat aktif. |

### Invariants Wajib

1. **Hanya satu karakter aktif pada satu waktu.**
2. **Karakter tidak aktif tidak menerima input**, tetapi tetap mengikuti moving surface dan tetap bisa terkena perubahan lingkungan.
3. **Hazard di realita tidak aktif dipause**, kecuali hazard tersebut baru diaktifkan oleh link saat realita itu menjadi aktif.
4. **Setiap link bersifat room-local**; tidak ada link yang memengaruhi room lain kecuali checkpoint.
5. **Semua perubahan link harus dapat di-reset** ke Room Snapshot.
6. **Tidak boleh ada link loop tak terbatas.** MVP membatasi kedalaman rantai link maksimal 2.
7. **Satu target object maksimal punya satu incoming link di MVP.** Multiple outgoing link diperbolehkan.
8. **Link tidak boleh menargetkan karakter secara langsung.** Karakter hanya terpengaruh lewat moving surface, hazard, atau objek fisik.
9. **Tidak ada jump, dash, atau vertical movement.** Semua pergerakan di bidang 2D top-down.
10. **Tidak ada gravity.** Karakter tidak jatuh.
11. **Spike adalah satu-satunya hazard di MVP.** Tidak ada pit, lava, atau laser.

---

## 2. Mekanik 1 — Sinkronisasi Dua Realita

### 2.1 Player Verbs

- **Switch** — berpindah kontrol antara Karakter A dan B.
- **Position** — memposisikan karakter sebelum switch.
- **Coordinate** — merencanakan urutan aksi kedua karakter.

**Catatan:** Verb yang tersedia untuk karakter aktif adalah Move (4-dir), Push/Pull, Activate, dan Switch. Tidak ada Jump/Dash.

### 2.2 Input & Precondition

| Aksi | Input | Precondition | Efek |
|---|---|---|---|
| Move | `WASD` / `←↑→↓` | Karakter active | Gerak 4-arah. |
| Push / Pull | `E` (menghadap objek) | Karakter active, dekat objek pushable | Dorong/tarik objek 1 tile. |
| Activate | `E` (menghadap objek) | Karakter active, dekat lever/button | Toggle / one-shot. |
| Switch | `Tab` / `Q` | Room state `Running`, cooldown siap | Pindah kontrol. |
| Reset Room | `R` | Kapan saja | Kembali ke Room Snapshot. |

**Aturan input:**

- `E` adalah **verb kontekstual**. Jika karakter menghadap pushable → push/pull. Jika menghadap lever/button → activate.
- Tidak ada tombol jump. `Space` tidak dipakai di MVP.
- Facing direction ditentukan oleh input gerak terakhir (4-arah diskret: atas, bawah, kiri, kanan).

### 2.3 State Model Karakter

```text
ActiveControlled
InactiveFrozen
InactiveOnMovingSurface
Repositioning
Dead / ResetPending
```

Aturan:

- `ActiveControlled`: menerima input, velocity 4-arah.
- `InactiveFrozen`: tidak menerima input; velocity = `Vector2.ZERO`; tetap mengikuti moving surface jika berdiri di atasnya.
- `InactiveOnMovingSurface`: seperti frozen, tetapi posisi di-update oleh surface yang bergerak.
- `Repositioning`: dipindahkan ke Safe Anchor dengan fade singkat; tidak bisa diinterupsi.
- `Dead/ResetPending`: memicu reset room.

**Catatan top-down:** Tidak ada state `Falling` atau `Grounded`. Karakter selalu di lantai (kecuali di spike yang akan memicu `Dead`).

### 2.4 State Machine RealityManager

```text
RunningA
RunningB
Switching
ResolvingLink
Repositioning
RoomReset
```

Aturan transisi:

- `RunningA` → `Switching` → `RunningB`
- `RunningB` → `Switching` → `RunningA`
- Saat `Switching`, input gerak diabaikan; input switch di-buffer maksimal satu.
- Link event yang terjadi saat `Switching` masuk queue dan diproses setelah state kembali `Running`.
- `ResolvingLink` hanya berlangsung selama aplikasi link; input ditahan maksimal 0,2 detik.
- `Repositioning` memblokir input sampai selesai.
- `RoomReset` memuat snapshot dan mengembalikan state ke `RunningA` atau `RunningB` sesuai checkpoint.

**Catatan:** `BossTransition` dihapus dari MVP — boss ditunda.

### 2.5 Aturan Switch

1. Switch hanya bisa dilakukan jika **cooldown siap**.
2. Saat switch:
   - Interaksi grab/pull yang sedang berlangsung **dilepas otomatis**.
   - Objek yang sedang di-push **disnap ke cell terakhir yang valid**.
   - Velocity karakter yang menjadi inactive di-nol-kan (`Vector2.ZERO`, semua arah).
   - Kamera/UI berpindah ke realita aktif (kamera per realita sudah fixed, hanya swap current).
   - Facing direction karakter inactive dipertahankan.
3. Switch tidak boleh memindahkan karakter secara spasial, kecuali terjadi desync.
4. Switch tidak boleh digunakan untuk "dodge" hazard secara instan; spike di realita tujuan sudah terlihat (karena kamera fixed, pemain bisa lihat lewat PiP).
5. Switch cooldown mencegah spam dan double-switch.

### 2.6 Aturan Realita Tidak Aktif

- Hazard (spike) di realita tidak aktif **dipause** — tidak ada damage saat inactive, kecuali karakter inactive diposisikan di spike yang **baru diaktifkan** oleh link.
- Moving surface yang bergerak karena link tetap bergerak; karakter inactive ikut terbawa jika berada di atasnya.
- Objek yang berubah karena link tetap berubah state-nya.
- Jika perubahan link membuat posisi karakter inactive tidak valid, sistem memicu **Safe Reposition**.
- Jika tidak ada Safe Anchor, room reset.

### 2.7 Safe Reposition

Dipicu jika:

- Karakter inactive berada di tile yang hilang (moving surface hilang).
- Karakter inactive terjebak di dalam objek solid.
- Karakter inactive berada di spike yang baru aktif akibat link.
- Moving surface yang dipijak karakter inactive hancur.

Prosedur:

1. Cari Safe Anchor terdekat dalam radius 5 tile di realita yang sama.
2. Prioritaskan anchor yang tidak berada di spike dan memiliki jalur keluar.
3. Pindahkan karakter dengan fade 0,3 detik.
4. Mainkan feedback "resonance stabilizer".
5. Jika tidak ada anchor valid, reset room.

**Catatan top-down:** Tidak ada kondisi "jatuh dari platform" karena tidak ada vertical. Spike bukan Safe Anchor.

### 2.8 Urutan Resolusi Link

Setiap aksi yang memicu link mengikuti urutan:

```text
1. Validasi aksi lokal.
2. Terapkan perubahan pada source object.
3. Emit ResonanceEvent(sourceId, newState, linkType).
4. ResonanceBus mencari link dengan source tersebut.
5. Untuk setiap target:
   a. Cek kondisi link.
   b. Jika delay > 0, masukkan ke queue.
   c. Jika target bisa berubah, terapkan perubahan.
   d. Jika target blocked, tangani sesuai link type.
6. Validasi posisi kedua karakter.
7. Jika invalid, Safe Reposition.
8. Feedback visual/audio.
```

Aturan anti-loop:

- Setiap event membawa `visitedLinks`.
- Link yang sudah diproses tidak diproses lagi dalam event yang sama.
- Kedalaman rantai maksimal 2 di MVP.
- Link dengan tipe one-way tidak memicu balik.

### 2.9 Feedback

| Kejadian | Visual | Audio | UI |
|---|---|---|---|
| Switch | Realita aktif menjadi saturasi penuh; inactive desaturasi | Whoosh + hum | Border warna realita aktif |
| Link trigger | Objek source dan target berdenyut | Nada resonance | Ikon link muncul |
| Link blocked | Objek bergetar merah | Buzz pendek | Prompt "terhalang" |
| Safe reposition | Fade karakter | Stabilizer tone | Notifikasi singkat |
| Cooldown switch | Ikon switch meredup | — | Cooldown radial |

**Catatan:** Karena kamera fixed, kedua realita terlihat sekaligus (A di layar utama, B di PiP). Efek "desaturasi realita inactive" penting untuk clarity.

### 2.10 Parameter Tuning Mekanik 1

| Parameter | Nilai Awal |
|---|---|
| Switch cooldown | 0,25 detik |
| Switch animation | 0,3 detik |
| Input buffer switch | 1 input |
| Safe reposition radius | 5 tile |
| Safe reposition fade | 0,3 detik |
| Link resolution hold | maks. 0,2 detik |
| Max link chain depth | 2 |
| Camera fixed per room | Ya (design constraint) |
| Tile size | 32 px |

### 2.11 Acceptance Criteria Mekanik 1

- Hanya satu karakter menerima input pada setiap frame.
- Switch tidak bisa dilakukan saat cooldown.
- Karakter inactive ikut bergerak saat moving surface di bawahnya bergerak.
- Spike di realita inactive tidak membunuh karakter.
- Link event saat switching diproses setelah switch selesai.
- Karakter inactive yang posisinya invalid dipindahkan ke Safe Anchor, bukan langsung mati.
- Room reset mengembalikan posisi, state objek, dan queue link ke snapshot.
- Tidak ada input jump di build manapun.

---

## 3. Mekanik 2 — Manipulasi Lingkungan

### 3.1 Player Verbs

- **Push** — mendorong objek satu tile ke arah hadap.
- **Pull** — menarik objek satu tile ke arah belakang.
- **Activate** — mengaktifkan lever, plate, button.
- ~~**Jump**~~ — dihapus.

### 3.2 Kategori Interactable

| Kategori | Contoh | Aturan |
|---|---|---|
| Pushable | Kotak, crate | Bisa didorong 1 tile ke arah hadap jika cell tujuan kosong. |
| Pullable | Kotak, crate | Bisa ditarik 1 tile jika cell belakang player kosong. |
| Toggle | Lever | State on/off. |
| Momentary | Plate | Aktif selama ada weight (karakter **atau** pushable di atasnya). |
| One-shot | Button | Aktif permanen sampai reset. |
| Moving Surface | Bridge, block, floor tile | Digerakkan oleh link. |
| Destructible | Dinding retak | Bisa dihancurkan; memicu link. |
| Hazard | Spike | Tile lantai. Karakter mati saat menyentuh saat aktif. |

**Catatan penting (Q-E):** Plate menerima **dua sumber weight**:

- Karakter (aktif maupun inactive).
- Pushable block yang digeser ke atas plate.

Ini memungkinkan puzzle: dorong block ke plate → plate tetap aktif permanen tanpa pemain harus berdiri di sana.

### 3.3 Aturan Push/Pull (4-Directional)

Rekomendasi MVP: **grid-based discrete push/pull**.

- Player harus berada di tile bersebelahan dan menghadap objek (4 arah: atas, bawah, kiri, kanan).
- Tekan `E` untuk push/pull satu tile ke arah hadap / belakang.
- Push valid jika:
  - Cell tujuan kosong.
  - Tidak ada karakter lain di cell tujuan.
  - Tidak ada hazard fatal di cell tujuan (spike aktif).
  - Tidak ada objek solid lain di cell tujuan.
- Pull valid jika:
  - Cell di belakang player kosong.
  - Objek bisa bergerak ke cell player saat ini.
- Durasi animasi 0,15 detik; selama animasi, input gerak ditahan.
- Jika objek terhubung ke link offset dan target blocked, aksi push/pull **di-rollback**: source kembali ke posisi semula, feedback "blocked".

**Facing direction:**

- Ditentukan oleh input gerak terakhir (W = atas, S = bawah, A = kiri, D = kanan).
- Jika input diagonal (W+D), pilih salah satu prioritas (mis. horizontal > vertikal) atau ambil yang terakhir diproses. **Rekomendasi MVP:** diagonal dilarang; hanya 4-arah murni.

### 3.4 Aturan Activate

- Lever: toggle on/off.
- Plate: aktif selama ada weight (karakter atau pushable) di atasnya.
- Button: one-shot (MVP).
- Interaksi memerlukan jarak maksimal 1 tile dan menghadap objek.
- Activation tidak bisa dilakukan saat karakter inactive.

**Ditunda:** timed button (durasi aktif terbatas) dan multi-button door. Akan dibedah di iterasi berikut.

### 3.5 Model Data Link

```text
RealityLink {
  id: string
  sourceId: string
  targetId: string
  type: Toggle | Offset | Mirror | OneWay | Delayed | Destructible
  delay: float
  oneShot: bool
  condition: optional
  offset_direction: Vector2i   # 4-arah (kiri/kanan/atas/bawah)
  mirror_mapping: Dictionary
}
```

### 3.6 Tipe Link Formal

| Tipe | Semantik | Contoh | Aturan Edge Case |
|---|---|---|---|
| Toggle | Source berubah state → target berubah state | Lever A membuka pintu B | Jika target sudah di state yang sama, tidak ada perubahan. |
| Offset | Source bergerak Δ → target bergerak Δ | Kotak A digeser ke kanan → bridge B memanjang ke kanan | Δ adalah `Vector2i` 4-arah. Jika target blocked, rollback source. |
| Mirror | Target state = mapping kebalikan source | Lever A up → lever B down | Mapping eksplisit per objek. |
| OneWay | Hanya source → target | Tombol A memunculkan bridge B | Perubahan target tidak memicu balik. |
| Delayed | Target berubah setelah `delay` detik | Plate A → bridge B muncul setelah 1 detik | Queue dibatalkan saat reset. Jika blocked saat apply, retry sekali lalu fail. |
| Destructible | Source hancur → target hilang/disable permanen | Dinding A dihancurkan → floor tile B hilang | One-shot sampai reset. |

**Catatan top-down:** `Offset` sekarang valid untuk 4 arah — bukan hanya horizontal seperti di platformer.

### 3.7 Aturan Resolusi Link Lingkungan

1. **Source action atomic**: jika link offset gagal, source rollback.
2. **Target blocked**:
   - Toggle: tetap berubah state; objek target mungkin tidak terlihat bergerak.
   - Offset: rollback source.
   - Delayed: retry sekali; jika tetap blocked, link fail dengan feedback.
3. **Multiple outgoing link** diperbolehkan; semua target diproses.
4. **Multiple incoming link** tidak diperbolehkan di MVP.
5. **Link chain** maksimal 2.
6. **Queue delayed link** disimpan per room dan dibersihkan saat reset.
7. **Link tidak boleh memindahkan karakter secara langsung**; hanya lewat moving surface atau hazard.

### 3.8 Interaksi dengan Karakter Inactive

- Jika moving surface bergerak dan karakter inactive berdiri di atasnya, karakter ikut bergerak.
- Jika moving surface hilang, karakter inactive memicu Safe Reposition.
- Jika target link adalah pintu yang menutup di posisi karakter inactive, karakter dianggap desync dan dipindahkan ke Safe Anchor.
- Jika karakter inactive berada di atas pushable yang bergerak karena link, karakter ikut bergerak.
- Jika spike baru aktif di bawah karakter inactive, Safe Reposition.

### 3.9 Feedback Lingkungan

| Kejadian | Visual | Audio |
|---|---|---|
| Objek bisa diinteraksi | Outline/glow saat dekat | Hum halus |
| Push/pull sukses | Snap animation | Thud |
| Push/pull blocked | Getar + warna merah | Buzz |
| Link aktif | Garis resonance antara source-target | Nada naik |
| Link delayed | Countdown ring | Tick |
| Link fail | Glitch singkat | Error tone |
| Plate pressed | Tile turun + glow | Click |
| Spike aktif | Animasi muncul | Hiss |

### 3.10 Parameter Tuning Mekanik 2

| Parameter | Nilai Awal |
|---|---|
| Interaksi jarak | 1 tile |
| Push/pull durasi | 0,15 detik |
| Push/pull grid | 1 tile |
| Push directions | 4 (atas/bawah/kiri/kanan) |
| Delayed default | 1,0 detik |
| Delayed retry | 1 kali |
| Max outgoing link per source | 3 |
| Max incoming link per target | 1 |
| Max chain depth | 2 |
| Reset queue clear | Ya |
| Character move speed | 220 px/s |
| Facing update | Saat input gerak masuk |
| Diagonal input | Ditolak (hanya 4-arah) |

### 3.11 Acceptance Criteria Mekanik 2

- Push ke cell blocked tidak mengubah posisi objek.
- Push bekerja di 4 arah (atas, bawah, kiri, kanan).
- Offset link yang target-nya blocked me-rollback source.
- Toggle link mengubah target meskipun target tidak terlihat bergerak.
- Delayed link diterapkan setelah delay dan dibatalkan saat reset.
- Destructible link hanya sekali sampai reset.
- Mirror link memakai mapping eksplisit dan tidak menyebabkan loop.
- Link chain depth 3 tidak dieksekusi.
- Karakter inactive di atas moving surface ikut bergerak.
- Karakter inactive yang terjebak memicu Safe Reposition.
- Plate tetap aktif saat karakter inactive berdiri di atasnya.
- Plate tetap aktif saat pushable block berada di atasnya.
- Semua state objek kembali ke snapshot saat reset.

---

## 4. Aturan Gabungan Antar-Mekanik

1. **Switch saat grab/pull**: interaksi dilepas; objek tetap di posisi terakhir yang valid.
2. **Switch saat push animation**: input ditahan sampai animasi selesai; switch di-buffer.
3. **Link event saat switching**: masuk queue, diproses setelah `Running`.
4. **Karakter inactive memicu plate**: plate tetap aktif karena karakter inactive tetap punya weight.
5. **Pushable memicu plate**: plate tetap aktif karena pushable punya weight.
6. **Karakter inactive di spike**: spike paused; tidak mati sampai realita menjadi aktif atau spike baru diaktifkan oleh link.
7. **Kedua karakter di exit zone**: win condition terpenuhi meskipun hanya satu yang aktif.
8. **Salah satu karakter mati**: room reset, bukan game over permanen.
9. **Queue delayed link saat room reset**: dibersihkan.
10. **Link yang menyebabkan kedua karakter desync**: prioritaskan Safe Reposition karakter inactive; jika gagal, reset room.
11. **Push pushable ke plate**: plate aktif, link trigger, dan pushable berhenti di plate.
12. **Push pushable yang berada di moving surface**: pushable ikut bergerak bersama surface.

---

## 5. Test Matrix Ringkas

| ID | Skenario | Ekspektasi |
|---|---|---|
| T1 | Switch saat cooldown | Ditolak |
| T2 | Switch saat bergerak | Velocity inactive = 0 |
| T3 | Inactive di moving surface | Ikut bergerak |
| T4 | Inactive di surface yang hilang | Safe Reposition |
| T5 | Spike di realita inactive | Tidak membunuh |
| T6 | Link event saat switching | Diproses setelah switch |
| T7 | Push ke cell blocked (4 arah) | Tidak bergerak |
| T8 | Offset link target blocked | Source rollback |
| T9 | Delayed link | Apply setelah delay |
| T10 | Reset saat delayed link pending | Queue clear |
| T11 | Destructible link | Sekali sampai reset |
| T12 | Chain depth 3 | Tidak dieksekusi |
| T13 | Dua outgoing link | Keduanya diproses |
| T14 | Inactive terjebak pintu | Safe Reposition |
| T15 | Kedua karakter di exit | Win |
| T16 | Push ke arah atas | Berfungsi |
| T17 | Push ke arah bawah | Berfungsi |
| T18 | Push ke arah kiri | Berfungsi |
| T19 | Push ke arah kanan | Berfungsi |
| T20 | Pushable di atas plate | Plate tetap aktif |
| T21 | Inactive di atas plate | Plate tetap aktif |
| T22 | Spike baru aktif di bawah inactive | Safe Reposition |
| T23 | Push diagonal | Ditolak |
| T24 | Input jump | Tidak ada efek (tombol tidak terdaftar) |

---

## 6. Catatan Implementasi untuk Prototype

- Gunakan **grid-based puzzle logic** untuk push/pull dan offset link agar rollback mudah.
- Pisahkan **state logic** dari **animasi**; animasi tidak boleh menentukan validitas.
- Simpan `RoomSnapshot` berisi posisi karakter, state objek, dan queue link.
- Gunakan event `ResonanceEvent` dengan `visitedLinks` untuk mencegah loop.
- Semua link harus bisa di-debug lewat overlay: source ID, target ID, type, state.
- Untuk MVP, batasi satu incoming link per target dan maksimal dua kedalaman chain.
- **Tidak ada gravity atau jump** — jangan tambahkan `is_on_floor()`, `gravity`, atau `jump_velocity`.
- Facing direction harus di-track eksplisit (`enum Facing { UP, DOWN, LEFT, RIGHT }`).
- Push/pull menggunakan tween 0,15s; selama tween, disable input.
- Kamera fixed per room: setiap room punya batas kamera (`Camera2D.limit_left/right/top/bottom`) yang mengunci view.
- PiP camera tetap follow karakter inactive (top-down).
- Spike gunakan `Area2D` yang berada di grup `hazards_a` / `hazards_b`.

---

## 7. Roadmap Dokumen Lanjutan

| Langkah | Dokumen | Status |
|---|---|---|
| 1 | Spesifikasi Mekanik Formal v2.0 (Top-Down) | **Selesai (dokumen ini)** |
| 2 | Level Design 8 Room (Top-Down) | Belum — redesign total |
| 3 | Arsitektur Godot 4 (Top-Down) | Belum — update 40% |
| 4 | Boss Design Document | Belum (ditunda) |
| 5 | Prototype Backlog (Top-Down) | Belum — update 30% |

---

## 8. Keputusan yang Masih Ditunda

Akan dibedah di iterasi berikut:

1. **Timed button** — durasi aktif terbatas, bisa trigger link dengan delay.
2. **Multi-button door** — pintu yang butuh 2+ tombol aktif bersamaan.
3. **Hazard tambahan** — pit, lava, laser (di luar scope MVP).
4. **Mekanik tambahan** — grab/throw, dash, echo pulse (di luar scope MVP).

Untuk sekarang: **kunci dulu plate-hold + push-block + spike + semua link types.**