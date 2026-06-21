import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/database_service.dart'; // <-- Import DatabaseService Anda
import 'kelola_hadiah_page.dart';
import 'laporan_anak_page.dart';

class DashboardOrtuPage extends StatefulWidget {
  const DashboardOrtuPage({super.key});

  @override
  State<DashboardOrtuPage> createState() => _DashboardOrtuPageState();
}

class _DashboardOrtuPageState extends State<DashboardOrtuPage> {
  final _databaseService = DatabaseService();
  final _namaController = TextEditingController();
  final _poinController = TextEditingController();
  bool _isSaving = false;

  // Fungsi Pop-up Dialog untuk Membuat Tugas Baru ke Cloud Firestore
  void _tambahTugasDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Tugas Baru 📝'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Tugas/Aktivitas',
              ),
            ),
            TextField(
              controller: _poinController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Poin Reward',
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
            onPressed: _isSaving ? null : () async {
              if (_namaController.text.isNotEmpty &&
                  _poinController.text.isNotEmpty) {
                
                Navigator.pop(context); // Tutup dialog duluan

                try {
                  // SIMPAN KE CLOUD FIRESTORE
                  await _databaseService.tambahTugasBaru(
                    namaTugas: _namaController.text,
                    deskripsi: 'Tugas harian anak',
                    kategori: 'Rutinitas',
                    poin: int.parse(_poinController.text),
                    wajibFoto: false,
                  );

                  _namaController.clear();
                  _poinController.clear();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tugas berhasil disimpan di Cloud Firestore! 🎉')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan tugas: $e')),
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
        title: const Text('Dashboard Orang Tua'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              // LOGOUT AMAN: Menghapus sesi Firebase Auth dan bersihkan stack navigasi
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.family_restroom, color: Colors.white),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keluarga Hebat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Status: 1 Anak Terhubung',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Menu Utama Kelola',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildMenuCard(
                  context,
                  Icons.add_task,
                  'Buat Tugas',
                  Colors.blue,
                  _tambahTugasDialog,
                ),
                _buildMenuCard(
                  context,
                  Icons.verified,
                  'Verifikasi Tugas',
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerifikasiTugasPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  Icons.card_giftcard,
                  'Kelola Hadiah',
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KelolaHadiahPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  Icons.analytics,
                  'Laporan Anak',
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaporanAnakPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// === HALAMAN BARU: VERIFIKASI TUGAS (FIRESTORE REAL-TIME) ===
class VerifikasiTugasPage extends StatefulWidget {
  const VerifikasiTugasPage({super.key});

  @override
  State<VerifikasiTugasPage> createState() => _VerifikasiTugasPageState();
}

class _VerifikasiTugasPageState extends State<VerifikasiTugasPage> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Tugas Anak'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _databaseService.dapatkanStreamVerifikasiTugas(), // Ambil data tugas berstatus 'Menunggu Verifikasi'
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Belum ada tugas dari Anak yang menunggu verifikasi. 🌟',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            );
          }

          final listPerluVerifikasi = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listPerluVerifikasi.length,
            itemBuilder: (context, index) {
              final doc = listPerluVerifikasi[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final taskId = data['taskId'] ?? '';
              final namaTugas = data['namaTugas'] ?? '';
              final poin = data['poin'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(
                    Icons.hourglass_top,
                    color: Colors.orange,
                  ),
                  title: Text(
                    namaTugas,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('+$poin Poin'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        // Kunci verifikasi ke Firestore cloud dengan menyertakan poin tugas
                        await _databaseService.verifikasiTugasAnak(taskId, poin);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tugas "$namaTugas" Berhasil Diverifikasi! Poin cair ke Anak 💸'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal melakukan verifikasi: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Verifikasi'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}