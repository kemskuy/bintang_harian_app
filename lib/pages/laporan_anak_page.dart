import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart'; // <-- Pastikan path import sudah benar

class LaporanAnakPage extends StatelessWidget {
  const LaporanAnakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Statistik Anak'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // BUNGKUS SELURUH BODY DENGAN STREAMBUILDER AGAR STATISTIK DAN LIST BISA MEMBACA DATA CLOUD
      body: StreamBuilder<QuerySnapshot>(
        stream: databaseService.dapatkanStreamTugas(), // Mengambil seluruh data tugas di Firestore
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Inisialisasi hitungan statistik default jika data masih kosong
          int totalTugas = 0;
          int tugasSelesai = 0;
          int tugasDiverifikasi = 0;
          int totalPoinDicairkan = 0;
          List<QueryDocumentSnapshot> dokumenTugas = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            dokumenTugas = snapshot.data!.docs;
            totalTugas = dokumenTugas.length;

            for (var doc in dokumenTugas) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Aktif';
              
              // Langsung ambil nilainya ke num dulu, baru dipaksa ke int via .toInt()
              final num rawPoin = data['poin'] ?? 0;
              final int poin = rawPoin.toInt();

              // Hitung tugas yang diklaim anak (Menunggu Verifikasi & Selesai)
              if (status == 'Menunggu Verifikasi' || status == 'Selesai') {
                tugasSelesai++;
              }

              // Hitung tugas yang sukses terverifikasi (Selesai)
              if (status == 'Selesai') {
                tugasDiverifikasi++;
                totalPoinDicairkan += poin; // DIJAMIN AMAN karena poin sudah pasti int
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Aktivitas ✨',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Ringkasan berbentuk Grid Statis Singkat - SEKARANG DINAMIS FIRESTORE
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Tugas', '$totalTugas', Colors.blue),
                    _buildStatCard('Klaim Anak', '$tugasSelesai', Colors.orange),
                    _buildStatCard('Diverifikasi', '$tugasDiverifikasi', Colors.green),
                    _buildStatCard('Total Poin', '$totalPoinDicairkan ⭐', Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Riwayat & Status Tugas 📋',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Daftar Semua Riwayat Tugas dari Cloud Firestore
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

                          // Menentukan teks status dan warna badge berdasarkan field 'status' Firestore
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
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
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