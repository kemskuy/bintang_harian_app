import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart';

class LaporanAnakPage extends StatelessWidget {
  const LaporanAnakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final String currentParentUid = databaseService.currentUid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Statistik Anak'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // MENGGUNAKAN MULTI-STREAM / GABUNGAN DATA SECARA REAL-TIME
      body: StreamBuilder<QuerySnapshot>(
  // Kita kunci aliran data tugas hanya yang cocok dengan parentId Ortu aktif!
  stream: FirebaseFirestore.instance
      .collection('tasks')
      .where('parentId', isEqualTo: currentParentUid)
      .snapshots(),
  builder: (context, tugasSnapshot) {
          if (tugasSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Inisialisasi hitungan statistik default
          int totalTugas = 0;
          int tugasSelesai = 0;
          int tugasDiverifikasi = 0;
          int totalPoinDicairkan = 0; // Ini akan menjadi akumulasi kotor (Total Poin)
          List<QueryDocumentSnapshot> dokumenTugas = [];

          if (tugasSnapshot.hasData && tugasSnapshot.data!.docs.isNotEmpty) {
            dokumenTugas = tugasSnapshot.data!.docs;
            totalTugas = dokumenTugas.length;

            for (var doc in dokumenTugas) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Aktif';
              
              final num rawPoin = data['poin'] ?? 0;
              final int poin = rawPoin.toInt();

              if (status == 'Menunggu Verifikasi' || status == 'Selesai') {
                tugasSelesai++;
              }

              if (status == 'Selesai') {
                tugasDiverifikasi++;
                totalPoinDicairkan += poin; 
              }
            }
          }

          // STREAM KEDUA: Membaca data rewards terverifikasi dan sisa poin anak saat ini
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rewards')
                .where('parentId', isEqualTo: currentParentUid)
                .where('status', isEqualTo: 'Selesai Diklaim')
                .snapshots(),
            builder: (context, rewardSnapshot) {
              int totalPoinDitukar = 0;

              if (rewardSnapshot.hasData && rewardSnapshot.data!.docs.isNotEmpty) {
                for (var doc in rewardSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final num hargaRaw = data['hargaPoin'] ?? 0;
                  totalPoinDitukar += hargaRaw.toInt();
                }
              }

              // Formula menghitung sisa poin bersih anak secara matematis (Total Didapat - Total Ditukar)
              int sisaPoinAnak = totalPoinDicairkan - totalPoinDitukar;
              if (sisaPoinAnak < 0) sisaPoinAnak = 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Aktivitas Tugas ✨',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),

                    // Grid untuk info tugas anak
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard('Total Tugas', '$totalTugas', Colors.blue),
                        _buildStatCard('Klaim Anak', '$tugasSelesai', Colors.orange),
                        _buildStatCard('Diverifikasi', '$tugasDiverifikasi', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Neraca & Segmentasi Poin Anak ⭐',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),

                    // Grid Baru Khusus Segmentasi Poin yang Sinkron dan Akurat
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                      children: [
                        _buildStatCard('Total Poin\n(Akumulasi)', '$totalPoinDicairkan', Colors.purple),
                        _buildStatCard('Poin Ditukar\n(Hadiah)', '$totalPoinDitukar', Colors.red.shade700),
                        _buildStatCard('Sisa Poin\n(Aktif)', '$sisaPoinAnak 🔥', Colors.amber.shade900),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Riwayat & Status Tugas 📋',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Daftar Semua Riwayat Tugas
                    dokumenTugas.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text('Belum ada riwayat tugas hari ini. 🌟'),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dokumenTugas.length,
                            itemBuilder: (context, index) {
                              final data = dokumenTugas[index].data() as Map<String, dynamic>;
                              
                              final namaTugas = data['namaTugas'] ?? '';
                              final num rawPoinList = data['poin'] ?? 0;
                              final int poin = rawPoinList.toInt();
                              final status = data['status'] ?? 'Aktif';

                              String statusText = 'Belum Selesai';
                              Color badgeColor = Colors.grey.shade200;
                              Color textColor = Colors.grey.shade700;

                              if (status == 'Selesai') {
                                statusText = 'Finish 🎉';
                                badgeColor = Colors.green.shade100;
                                textColor = Colors.green.shade700;
                              } else if (status == 'Menunggu Verifikasi') {
                                statusText = 'Menunggu Cek ⏳';
                                badgeColor = Colors.orange.shade100;
                                textColor = Colors.orange.shade700;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    namaTugas,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('+$poin Poin'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}