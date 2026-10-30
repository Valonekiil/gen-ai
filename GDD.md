# Mini Game Design Document: Splitbound

## 1. Executive Summary

- **Genre:** Puzzle Platformer
- **Target Audiens:** Pemain PC usia 15–35 tahun yang menyukai puzzle-platformer berbasis eksplorasi, manipulasi ruang, dan pemecahan masalah.
- **High Concept:** Seorang penjelajah kehilangan separuh tubuhnya di dimensi paralel dan harus mengendalikan dua versi dirinya secara bergantian untuk melarikan diri dari fasilitas penelitian yang sedang runtuh.
- **Unique Selling Point (USP):** **Dual-Reality Puzzle:** pemain mengendalikan dua versi karakter yang berada di realita berbeda tetapi saling memengaruhi; tindakan satu karakter dapat mengubah lingkungan yang dihadapi karakter lainnya.

## 2. Gameplay & Mechanics

- **Core Loop:** Amati kondisi kedua realita → Pindahkan kontrol antara dua versi karakter → Atur posisi dan tindakan masing-masing karakter → Manipulasi lingkungan → Sinkronkan kedua karakter → Pecahkan puzzle dan lakukan platforming → Mencapai area berikutnya.
- **Player Verbs Utama:** Move, Jump, Switch, Push, Pull, Activate, Coordinate.
- **Rincian Mekanik:**
  - **Nama Mekanik: Sinkronisasi Dua Realita**
    - **Player Verbs:** Switch, Position, Coordinate
    - **Core Loop:** Amati kondisi kedua realita → Pindahkan kontrol antara dua versi karakter → Atur posisi dan tindakan masing-masing karakter → Sinkronkan keduanya untuk membuka jalur → Lanjutkan eksplorasi.
    - **Aturan Sistem:** Kedua versi karakter berada di lingkungan berbeda tetapi saling memengaruhi. Tindakan satu karakter dapat mengubah objek atau kondisi di realita lainnya. Pemain hanya mengendalikan satu karakter pada satu waktu sehingga harus merencanakan posisi karakter yang tidak sedang dikendalikan.
  - **Nama Mekanik: Manipulasi Lingkungan**
    - **Player Verbs:** Push, Pull, Activate, Jump
    - **Core Loop:** Temukan hambatan atau objek interaktif → Analisis hubungan objek di kedua realita → Manipulasi objek menggunakan salah satu karakter → Ciptakan jalur bagi karakter lainnya → Gunakan jalur untuk mencapai area berikutnya.
    - **Aturan Sistem:** Objek tertentu memiliki keadaan berbeda di setiap realita. Perubahan pada objek di satu realita dapat menciptakan, menghilangkan, atau mengubah fungsi objek di realita lainnya. Pemain harus menggunakan interaksi kedua karakter secara berurutan untuk menyelesaikan puzzle dan melanjutkan platforming.
- **Win / Lose Condition:**
  - **Win:** Kedua versi karakter berhasil mencapai titik pelarian atau menyelesaikan seluruh rangkaian fasilitas.
  - **Lose:** Salah satu karakter terkena bahaya fatal, terjebak dalam kondisi yang tidak dapat dipulihkan, atau gagal keluar sebelum keruntuhan fasilitas mencapai area tersebut.

## 3. World & Entitas

- **Latar Belakang Cerita:**
  Sebuah fasilitas penelitian dimensi melakukan eksperimen untuk menghubungkan dua realita. Eksperimen mengalami kegagalan dan menyebabkan seorang penjelajah terpecah menjadi dua versi dirinya yang berada di realita berbeda. Ketika fasilitas mulai runtuh akibat ketidakstabilan dimensi, kedua versi tersebut harus bekerja sama untuk menemukan jalan keluar. Sepanjang perjalanan, pemain menemukan bahwa hubungan antara kedua realita bukan sekadar kecelakaan, melainkan bagian dari eksperimen yang jauh lebih besar.
- **Profil Entitas & Karakter:**
  - **Karakter Utama**
    - **Nama:** The Explorer / Protagonis
    - **Peran:** Penjelajah yang terpecah menjadi dua versi di dimensi paralel.
    - **Stat Utama:** Kesehatan (100), Stabilitas Dimensi (100)
    - **Kemampuan Khusus:** Berpindah kendali antara dua versi dirinya dan memanfaatkan interaksi antar-realita untuk menyelesaikan puzzle.
  - **NPC Pendamping**
    - **Nama:** Echo-07 (Eko)
    - **Peran:** Peneliti Dimensi Paralel
    - **Stat Utama:** Stabilitas Dimensi (80), Kecepatan Analisis (Tinggi)
    - **Kemampuan Khusus:** Membaca anomali antar-realita dan memberikan petunjuk mengenai objek yang dapat berinteraksi atau berubah ketika karakter berpindah dimensi.
  - **Musuh Utama / Boss Area**
    - **Nama:** The Convergence
    - **Peran:** Entitas Penjaga Fasilitas
    - **Stat Utama:** Kesehatan (1.000), Stabilitas Dimensi (Sangat Tinggi)
    - **Kemampuan Khusus:** Menggabungkan kedua realita secara paksa dan mengubah posisi platform serta objek secara dinamis. Pemain harus mengendalikan kedua versi karakter untuk menghindari serangan dan menemukan titik lemahnya.

## 4. Technical Scope & Engine Recommendation

- **Platform Utama:** PC — Steam
- **Rekomendasi Game Engine (Godot 4 / Unity):** **Godot 4**
  - Cocok untuk game 2D puzzle-platformer karena memiliki sistem **2D physics, CharacterBody2D, TileMap, AnimationPlayer, signals, dan scene system** yang kuat.
  - Ringan dan relatif cepat untuk pengembangan tim indie.
  - Sistem scene dan node memudahkan pemisahan **Realita A dan Realita B** sebagai level/lingkungan yang saling terhubung.
  - Open-source tanpa biaya lisensi engine, sehingga sesuai untuk proyek indie dengan scope kecil hingga menengah.
  - Untuk prototype *Splitbound*, Godot 4 memungkinkan tim memvalidasi mekanik inti **dual-reality switching** terlebih dahulu sebelum mengembangkan konten, visual, dan level dalam skala besar.


I have an error in my Godot script.
Error message:
Error at (17, 20): Too many arguments for "move_and_slide()" call. Expected at most 0 but received 1.
Relevant script:
extends CharacterBody2D

@export var speed: float = 300.0

func _process(delta):
	var direction = Vector2(0, 0)
	
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	
	if direction != Vector2(0, 0):
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide(velocity)
Expected behavior:
Nara should move left and right using keyboard input.
Please:
1. identify the likely cause,
2. identify the problematic line,
3. explain the error in beginner-friendly language,
4. suggest the smallest necessary fix.
Do not rewrite unrelated parts of the code.