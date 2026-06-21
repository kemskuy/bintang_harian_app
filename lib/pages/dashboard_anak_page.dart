import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/database_service.dart';

class DashboardAnakPage extends StatefulWidget {
  const DashboardAnakPage({super.key});

  @override
  State<DashboardAnakPage> createState() => _DashboardAnakPageState();
}

class _DashboardAnakPageState extends State<DashboardAnakPage> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Anak'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
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
            // =========================================================
            // WIDGET KARTU POIN REAL-TIME DARI CLOUD FIRESTORE
            // =========================================================
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(), // Mendengarkan perubahan dokumen user ini secara langsung
              builder: (context, snapshot) {
                int totalPoin = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  // Mengambil field totalPoin dari DB, jika belum ada set default ke 0
                  totalPoin = userData['totalPoin'] ?? 0;
                }

                return Card(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.stars, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Poin Kamu ⭐',
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            Text(
                              '$totalPoin Poin', // <-- Sekarang angkanya otomatis dinamis!
                              style: const TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Tugas Hari Ini 📝',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),

            // STREAMBUILDER DAFTAR TUGAS DARI CLOUD FIRESTORE
            StreamBuilder<QuerySnapshot>(
              stream: _databaseService.dapatkanStreamTugas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Belum ada tugas hari ini. ✨'),
                    ),
                  );
                }

                final dokumenTugas = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dokumenTugas.length,
                  itemBuilder: (context, index) {
                    final doc = dokumenTugas[index]; 
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final taskId = data['taskId'] ?? '';
                    final namaTugas = data['namaTugas'] ?? '';
                    final kategori = data['kategori'] ?? 'Rutinitas';
                    final poin = data['poin'] ?? 0;
                    final status = data['status'] ?? 'Aktif';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: status == 'Selesai' 
                              ? Colors.green 
                              : (status == 'Menunggu Verifikasi' ? Colors.orange : Colors.amber),
                          child: const Icon(Icons.star, color: Colors.white),
                        ),
                        title: Text(
                          namaTugas,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$kategori • $poin Poin Bintang ⭐'),
                        
                        // TOMBOL ELEMEN SELESAI / STATUS NYA
                        trailing: status == 'Aktif'
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () async {
                                  try {
                                    await _databaseService.ajukanSelesaiTugas(taskId);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Tugas "$namaTugas" dikirim ke Orang Tua untuk diverifikasi! ⏳')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menyelesaikan tugas: $e')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Selesai'),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'Selesai' ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'Selesai' ? Colors.green.shade800 : Colors.orange.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}