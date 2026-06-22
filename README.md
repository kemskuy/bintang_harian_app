\# Bintang Harian App 🚀 (Versi 1.1)
## Log Perubahan (Changelog) V1.1.0
- Penambahan fitur real-time sync antara Ortu dan Anak via parentId.
- Implementasi menu persetujuan klaim Toko Hadiah secara atomik.
- Penambahan visualisasi ringkasan tugas dan grafik progres harian di Dashboard Anak.



Aplikasi manajemen tugas anak berbasis gamifikasi untuk meningkatkan kedisiplinan harian melalui sistem \*reward\* poin. Aplikasi ini menggunakan \*\*Flutter\*\* untuk \*frontend\* dan \*\*Cloud Firestore (Firebase)\*\* sebagai \*database real-time backend\*.



\---



\## ✨ Fitur Utama (Versi 1.0)

\* \*\*Multi-Role Dashboard\*\*: Halaman khusus untuk Orang Tua dan Anak dengan antarmuka yang ramah.

\* \*\*Manajemen Tugas Real-Time\*\*: Orang Tua dapat membuat tugas, dan Anak dapat langsung mengklaim tugas yang telah selesai.

\* \*\*Sistem Verifikasi Aman\*\*: Proses persetujuan tugas menggunakan \*Firebase Transaction\* untuk memastikan validitas data.

\* \*\*Akumulasi Poin Otomatis\*\*: Saldo poin Anak otomatis bertambah secara \*real-time\* setelah diverifikasi oleh Orang Tua.

\* \*\*Statistik \& Laporan Aktivitas\*\*: Ringkasan data dalam bentuk \*Grid Card\* dinamis dan riwayat status tugas yang sinkron langsung dengan cloud.



\## 🛠️ Teknologi yang Digunakan

\* \*\*Framework\*\*: Flutter (Dart)

\* \*\*Database \& Backend\*\*: Firebase Auth \& Cloud Firestore

\* \*\*State Management \& UI\*\*: StreamBuilder \& List/Grid View dinamis



\## 📂 Struktur Proyek

\* `lib/data/` : Mengelola logika koneksi database (\*DatabaseService\*).

\* `lib/pages/` : Halaman UI (\*Dashboard\*, \*Laporan\*, \*Login\*).

\* `lib/models/` : Struktur data / cetak biru objek tugas.



\---



\## 📸 Demo Aplikasi

* next akan di publish



\---



\*Dikembangkan oleh \[Andy\_Ahmad] sebagai Proyek Bukti Kasih Sayang ke anak saya Kafka Ashilla Y.\*

