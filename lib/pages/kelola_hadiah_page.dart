import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart'; // <-- Pastikan import database service Anda

class KelolaHadiahPage extends StatefulWidget {
  const KelolaHadiahPage({super.key});

  @override
  State<KelolaHadiahPage> createState() => _KelolaHadiahPageState();
}

class _KelolaHadiahPageState extends State<KelolaHadiahPage> {
  final _databaseService = DatabaseService();
  final _namaHadiahController = TextEditingController();
  final _hargaPoinController = TextEditingController();
  final bool _isSaving = false;

  void _tambahHadiahDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Hadiah Baru 🎁'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaHadiahController,
              decoration: const InputDecoration(
                labelText: 'Nama Hadiah (ex: Mainan Mobil)',
                hintText: 'Tambahkan emoji agar seru ✨',
              ),
            ),
            TextField(
              controller: _hargaPoinController,
              decoration: const InputDecoration(
                labelText: 'Harga (Jumlah Poin Bintang)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: _isSaving
                ? null
                : () async {
                    if (_namaHadiahController.text.isNotEmpty &&
                        _hargaPoinController.text.isNotEmpty) {
                      Navigator.pop(context); // Tutup dialog duluan

                      try {
                        // Ambil UID Orang Tua aktif terlebih dahulu
                        final String uidOrangTua =
                            _databaseService.currentUid ?? '';

                        // Masukkan ke dalam parameter fungsi (Sudah disesuaikan nama controllernya)
                        await _databaseService.tambahHadiahBaru(
                          nama: _namaHadiahController.text, // <-- Gunakan nama asli ini gaes
                          hargaPoin: int.parse(_hargaPoinController.text), // <-- Gunakan harga asli ini gaes
                          parentId: uidOrangTua,
                        );

                        _namaHadiahController.clear();
                        _hargaPoinController.clear();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hadiah baru berhasil ditambahkan ke Store! 🎉',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menambahkan hadiah: $e'),
                            ),
                          );
                        }
                      }
                    }
                  },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Toko Hadiah'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _databaseService.dapatkanStreamHadiah(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Belum ada hadiah di toko. Klik tombol + di bawah untuk menambah! 🛒',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final dokumenHadiah = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dokumenHadiah.length,
            itemBuilder: (context, index) {
              final data = dokumenHadiah[index].data() as Map<String, dynamic>;
              final rewardId = data['rewardId'] ?? '';
              final nama = data['nama'] ?? '';
              final hargaPoin = data['hargaPoin'] ?? 0;
              final sudahDitebus = data['sudahDitebus'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                  title: Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Harga: $hargaPoin Poin Bintang ⭐'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sudahDitebus)
                        const Text(
                          'Sudah Ditukar Anak',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          try {
                            await _databaseService.hapusHadiah(rewardId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hadiah berhasil dihapus.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menghapus: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: _tambahHadiahDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
