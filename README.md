# 🌱 Dailio — Habit Tracker App

> *"Small Steps, Every Day."* or *"Grow Through Consistency."*

Dailio adalah aplikasi habit tracker modern berbasis offline-first yang dirancang untuk membantu pengguna membangun sistem kebiasaan kecil secara konsisten setiap hari. Dailio berfokus pada **proses & pertumbuhan bertahap**, bukan hanya hasil akhir yang instan. Karena pada akhirnya, **"Konsistensi mengalahkan intensitas."**

---

## 🎨 Filosofi Brand & Identitas

### 1. Filosofi Nama "Dailio"
Nama **Dailio** lahir dari gabungan dua nilai utama:
*   **Daily** → Merepresentasikan tindakan atau kebiasaan kecil yang dilakukan secara disiplin setiap hari.
*   **Akhiran "-io"** → Memberikan sentuhan modern, teknologi, progresif, dan berorientasi masa depan.
*   *Secara implisit*, pelafalan Dailio juga terdengar seperti perpaduan **"Daily + Grow"** (Tindakan harian yang menumbuhkan).

### 2. Filosofi Logo 🌿
Logo Dailio melambangkan visualisasi dari perjalanan pengembangan diri pengguna:
*   ⭕ **Lingkaran (Circle):** Melambangkan perjalanan berkelanjutan (*continuous journey*). Tidak ada garis finish dalam pengembangan diri; setiap hari adalah siklus baru untuk bertumbuh.
*   ✔️ **Checkmark:** Simbol tindakan nyata. Ini melambangkan aksi konkret yang telah diselesaikan, bukan sekadar rencana atau mimpi.
*   🌿 **Daun (Leaf):** Simbol pertumbuhan (*growth*). Mengingatkan bahwa perubahan kecil yang disiram konsistensi setiap hari akan tumbuh menjadi pohon kebiasaan yang kokoh dalam jangka panjang.

### 3. Filosofi Produk & Nilai Inti
Mayoritas aplikasi produktivitas fokus pada pemenuhan target besar (*goals-oriented*). Dailio berbeda:
*   **Focus on Process:** Dailio didesain untuk menghargai setiap langkah kecil yang diambil pengguna.
*   **No Judgment:** Dailio berkarakter tenang, mendukung, disiplin, namun tidak menghakimi pengguna saat mereka melewatkan satu hari.
*   **Progress over Perfection:** Menjadi sedikit lebih baik dibanding kemarin adalah kemenangan sesungguhnya.

---

## 👥 Brand Personality (Karakter Dailio)
Jika Dailio adalah manusia, ia akan memiliki sifat:
*   **Tenang & Nyaman:** Menggunakan palet warna "Calm Productivity Dark" agar tidak stressful secara psikologis.
*   **Mendukung:** Selalu memberikan dorongan positif.
*   **Disiplin:** Konsisten mengingatkan dengan cara yang elegan.
*   **Fokus pada Progres:** Menekankan pentingnya rantai kebiasaan (*streak*) daripada kesempurnaan mutlak.

> ❌ **Bukan:** *"Ayo kerja lebih keras lagi! Jangan malas!"*
> 
> ✅ **Tetapi:** *"Lakukan satu langkah kecil lagi untuk hari ini. Kamu sedang bertumbuh."*

---

## 📲 Deskripsi App Store
**Dailio — Build meaningful habits, one day at a time.**

*Track your routines, maintain streaks, monitor your progress, and turn small daily actions into lasting growth. Dailio is designed to help you stay consistent, stay focused, and become the person you want to be—one checkmark at a time.*

---

## 🛠️ Tech Stack & Arsitektur
Dailio dibangun dengan standar industri modern yang scalable, clean, dan production-ready:

*   **Framework:** [Flutter Latest Stable](https://flutter.dev)
*   **Database:** SQLite menggunakan package [sqflite](https://pub.dev/packages/sqflite) (Offline-First)
*   **State Management:** [Riverpod](https://riverpod.dev) (Modern & Safe State Management)
*   **Routing:** [go_router](https://pub.dev/packages/go_router) (Declarative Routing)
*   **Arsitektur:** **Clean Architecture** (Modular, terbagi menjadi layer *Domain*, *Data*, dan *Presentation*)
*   **Tema UI:** **Calm Productivity Dark** (Palet warna yang menenangkan secara psikologis: Emerald Green, Deep Slate, & Soft Blue)

---

## 📁 Struktur Folder Proyek
```text
lib/
├── core/                  # Utilitas inti, database helper, base errors/failures
│   ├── database/          # SQLite database helper & migrasi
│   ├── errors/            # Kustom exception & hasil pemrosesan (Result)
│   ├── usecase/           # Kontrak dasar UseCase
│   └── utils/             # Helper tanggal & formatter
├── features/              # Fitur-fitur modular (Habits & Tracking)
│   ├── habits/            # Fitur Manajemen Habit (CRUD & Statistik)
│   │   ├── domain/        # Entitas murni, Usecases, & Interface Repository
│   │   ├── data/          # Model data (JSON mapper) & Implementasi Repository
│   │   └── presentation/  # State controller (Riverpod) & UI Pages/Widgets
│   └── tracking/          # Fitur Tracking Harian & Streak System
└── shared/                # Widget, tema, dan provider global yang dipakai bersama
```

---

*Dailio — "Grow Through Consistency."* 🌱✨
