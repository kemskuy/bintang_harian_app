import 'package:flutter/material.dart';
import '../data/database_service.dart'; // <-- 1. Pastikan import DatabaseService Anda

class PilihPeranPage extends StatefulWidget {
  const PilihPeranPage({super.key});

  @override
  State<PilihPeranPage> createState() => _PilihPeranPageState();
}

class _PilihPeranPageState extends State<PilihPeranPage> {
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  // Fungsi untuk memproses pilihan peran ke Firestore
  void _eksekusiPilihPeran(String peran, String ruteTujuan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simpan status peran secara permanen ke Firebase Firestore
      await _dbService.simpanPeranUser(peran);

      if (mounted) {
        // Gunakan rute nama dari main.dart agar navigasi bersih
        Navigator.pushReplacementNamed(context, ruteTujuan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan peran: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Peran'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Tampilan loading saat simpan ke cloud
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Siapa yang menggunakan aplikasi ini?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  // Tombol Orang Tua
                  Card(
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.supervisor_account,
                        size: 40,
                        color: Colors.indigo,
                      ),
                      title: const Text(
                        'Saya Orang Tua',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Membuat tugas, verifikasi, dan kelola hadiah untuk anak',
                      ),
                      onTap: () => _eksekusiPilihPeran('Orang Tua', '/dashboard-ortu'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Anak
                  Card(
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.child_care,
                        size: 40,
                        color: Colors.orange,
                      ),
                      title: const Text(
                        'Saya Anak',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Lihat tugas harian, kumpulkan poin, dan tukar hadiah seru',
                      ),
                      onTap: () => _eksekusiPilihPeran('Anak', '/dashboard-anak'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}