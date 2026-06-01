# 🌱 Panduan Format CSV Cadangan Dailio

Dailio mendukung ekspor dan impor data kebiasaan (habits) secara lokal menggunakan format **`.csv` (Comma-Separated Values)**. Format ini sangat hemat ukuran berkas, efisien, dan dapat dibuka atau diedit sebagai tabel rapi langsung melalui aplikasi lembar kerja seperti **Microsoft Excel** atau **Google Sheets**.

Dokumen ini berfungsi sebagai panduan skema kolom bagi Anda jika ingin membuat, menyunting, atau menyusun file CSV secara manual untuk langsung diimpor ke dalam aplikasi Dailio.

---

## 📋 Struktur Kolom CSV Utama

File CSV Dailio menggunakan baris pertama sebagai header kolom (*case-sensitive*), diikuti oleh baris data habit di bawahnya. 

Berikut adalah contoh baris header dan data dasar:

```csv
id,name,description,category,type,created_at,is_archived,reminder_time,color
"d8b2e5a7-9c12-4f8e-a2b3-5c7d8e9f0a1b","Minum Air Putih","Minum 8 gelas air per hari agar tubuh terhidrasi","Kesehatan","daily","2026-06-02T00:00:00.000Z",0,"08:00",4284128256
```

---

## 🏷️ Penjelasan Setiap Kolom (Fields Schema)

Setiap kolom pada baris data didefinisikan secara urut sebagai berikut:

| Nama Kolom | Wajib | Tipe Data | Deskripsi & Aturan Nilai |
| :--- | :---: | :--- | :--- |
| **`id`** | Tidak | String (UUID) | ID unik untuk mengidentifikasi habit. Jika dikosongkan, Dailio akan otomatis membuatkan UUID baru yang unik saat proses impor dilakukan. |
| **`name`** | **Ya** | String | Nama kebiasaan yang ingin Anda lakukan (maksimal disarankan 50 karakter). |
| **`description`** | Tidak | String | Detail atau instruksi tambahan tentang kebiasaan tersebut. Bisa dikosongkan jika tidak ada. |
| **`category`** | **Ya** | String | Kategori habit Anda. Disarankan menggunakan kategori default: `Kesehatan`, `Pikiran`, `Olahraga`, `Belajar`, atau `Umum`. |
| **`type`** | **Ya** | String | Frekuensi pengulangan. Hanya menerima salah satu dari dua nilai: `daily` (harian) atau `weekly` (mingguan). |
| **`created_at`** | **Ya** | ISO 8601 String | Waktu pembuatan kebiasaan. Menggunakan format standar ISO-8601, misalnya: `2026-06-02T00:00:00.000Z`. |
| **`is_archived`** | **Ya** | Integer (0/1) | Status arsip. Gunakan `0` untuk habit aktif (tampil di dashboard), atau `1` untuk habit yang diarsipkan (disembunyikan). |
| **`reminder_time`** | Tidak | String (HH:MM) | Waktu pengingat harian menggunakan format 24 jam. Contoh: `07:30`, `19:15`. Biarkan kosong jika tidak mengaktifkan pengingat. |
| **`color`** | **Ya** | Integer (ARGB) | Nilai warna representasi integer 32-bit (ARGB). Beberapa nilai warna standar Calm Productivity Dark Dailio yang siap dipakai: <br> • **Blue Primary:** `4284128256` *(0xFF5AA9FF)* <br> • **Emerald Green:** `4283063936` *(0xFF4ADE80)* <br> • **Warning Gold:** `4294688292` *(0xFFFBBF24)* <br> • **Crimson Danger:** `4294652293` *(0xFFFB7185)* |

---

## 📝 Aturan Penulisan Karakter Khusus (Escaping Rules)

Dailio menggunakan parser CSV tangguh yang mendukung karakter khusus. Jika Anda menyunting berkas CSV menggunakan aplikasi editor teks biasa (seperti Notepad), pastikan Anda mematuhi aturan berikut:

1. **Gunakan Tanda Petik Ganda (`"`)**: Jika kolom teks mengandung karakter koma (`,`), tanda petik ganda (`"`), atau baris baru (`\n`), kolom tersebut **harus** dibungkus oleh sepasang tanda petik ganda.
   * *Contoh:* `"Membaca Buku, Menulis Jurnal"`
2. **Meloloskan Tanda Petik Ganda (`""`)**: Jika teks di dalam kolom mengandung tanda petik ganda, loloskan tanda petik tersebut dengan menulisnya dua kali berurutan.
   * *Contoh:* Untuk teks `Belajar "Flutter" Menyenangkan`, tulis di CSV sebagai: `"Belajar ""Flutter"" Menyenangkan"`

*Catatan: Jika Anda menggunakan Microsoft Excel atau Google Sheets dan menyimpannya sebagai `.csv`, aplikasi tersebut akan menangani pemformatan ini secara otomatis.*

---

## 📥 Contoh Berkas Siap Salin-Tempel (3 Kebiasaan)

Anda bisa menyalin teks di bawah ini, menyimpannya sebagai berkas dengan ekstensi **`.csv`** (misalnya: `cadangan_dailio.csv`), lalu mengimpornya langsung di halaman **Profil -> Impor (.csv)** untuk pengujian cepat!

```csv
id,name,description,category,type,created_at,is_archived,reminder_time,color
"7c9b8a3f-2d1e-4c5b-9d8e-7f6a5b4c3d2e","Meditasi Pagi 🌿","Bernapas tenang selama 10 menit setelah bangun tidur","Pikiran","daily","2026-06-02T06:00:00.000Z",0,"06:30",4283063936
"9e8d7c6b-5a4f-3e2d-1c0b-9a8f7e6d5c4b","Membaca 10 Halaman Buku 📚","Membaca buku non-fiksi untuk menambah wawasan","Belajar","daily","2026-06-02T20:00:00.000Z",0,"20:30",4284128256
"1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d","Lari Sore 🏃‍♂️","Lari keliling komplek rumah sejauh 3 km","Olahraga","weekly","2026-06-02T16:00:00.000Z",0,"17:00",4294688292
```
