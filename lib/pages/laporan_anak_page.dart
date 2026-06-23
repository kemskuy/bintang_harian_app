import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart';

class LaporanAnakPage extends StatefulWidget {
  const LaporanAnakPage({super.key});

  @override
  State<LaporanAnakPage> createState() => _LaporanAnakPageState();
}

class _LaporanAnakPageState extends State<LaporanAnakPage> {
  final _databaseService = DatabaseService();
  
  late DateTime _tanggalTerpilih;
  late String _tanggalTerpilihText;

  @override
  void initState() {
    super.initState();
    _tanggalTerpilih = DateTime.now();
    _tanggalTerpilihText = _tanggalTerpilih.toIso8601String().substring(0, 10);
  }

  String _formatHariTeks(DateTime dt) {
    final sekarang = DateTime.now();
    final kemarin = DateTime.now().subtract(const Duration(days: 1));
    
    final dtText = dt.toIso8601String().substring(0, 10);
    final sekarangText = sekarang.toIso8601String().substring(0, 10);
    final kemarinText = kemarin.toIso8601String().substring(0, 10);

    if (dtText == sekarangText) return 'Hari Ini';
    if (dtText == kemarinText) return 'Kemarin';
    
    List<String> namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${namaHari[dt.weekday - 1]}, ${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final String currentParentUid = _databaseService.currentUid ?? '';
    final String hariIniText = DateTime.now().toIso8601String().substring(0, 10);

    List<DateTime> listTujuhHari = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: index));
    }).reversed.toList(); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Statistik Anak'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // =========================================================================
          // WIDGET SLIDER HORIZONTAL PILIH HARI ✨
          // =========================================================================
          Container(
            height: 75,
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: listTujuhHari.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final dateItem = listTujuhHari[index];
                final String dateItemText = dateItem.toIso8601String().substring(0, 10);
                final bool isSelected = dateItemText == _tanggalTerpilihText;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tanggalTerpilih = dateItem;
                      _tanggalTerpilihText = dateItemText;
                    });
                  },
                  child: Container(
                    width: 85,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.indigo : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatHariTeks(dateItem),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateItem.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.indigo.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // =========================================================================
          // AREA DATA CORE GLOBAL & TEMPORAL INTEGRATION BRAY
          // =========================================================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Ambil SELURUH rekam log history tanpa filter tanggal untuk hitung Neraca Total Poin bray!
              stream: FirebaseFirestore.instance
                  .collection('task_history')
                  .where('parentId', isEqualTo: currentParentUid)
                  .snapshots(),
              builder: (context, globalHistorySnapshot) {
                if (globalHistorySnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allHistoryDocs = globalHistorySnapshot.data?.docs ?? [];

                // 1. Hitung Akumulasi Poin Total Sepanjang Masa secara absolut gaes!
                int totalPoinKumulatifMurni = 0;
                for (var doc in allHistoryDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] == 'Selesai') {
                    final num rawPoin = data['poin'] ?? 0;
                    totalPoinKumulatifMurni += rawPoin.toInt();
                  }
                }

                // 2. Filter data khusus untuk tanggal terpilih di slider saat ini bray
                final historyDocsHariTerpilih = allHistoryDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['tanggalLog'] == _tanggalTerpilihText;
                }).toList();

                // 3. Monitor data master template tugas aktif untuk menghitung target hari ini
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tasks')
                      .where('parentId', isEqualTo: currentParentUid)
                      .snapshots(),
                  builder: (context, tasksSnapshot) {
                    final masterTasks = tasksSnapshot.data?.docs ?? [];
                    bool targetHariIniTerpilih = _tanggalTerpilihText == hariIniText;

                    // Hitung total target tugas hari terpilih
                    int totalTugas = 0;
                    if (targetHariIniTerpilih) {
                      totalTugas = masterTasks.length;
                    } else {
                      if (historyDocsHariTerpilih.isNotEmpty) {
                        final firstDocData = historyDocsHariTerpilih.first.data() as Map<String, dynamic>;
                        totalTugas = firstDocData['totalTugasHariIni'] ?? masterTasks.length;
                      } else {
                        totalTugas = 0;
                      }
                    }

                    // Hitung selesai & belum selesai harian
                    int tugasSelesai = historyDocsHariTerpilih.where((doc) {
                      final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                      return status == 'Menunggu Verifikasi' || status == 'Selesai';
                    }).length;

                    int tugasBelumSelesai = totalTugas - tugasSelesai;
                    if (tugasBelumSelesai < 0) tugasBelumSelesai = 0;

                    // Stream 3: Hitung total kotor pengeluaran penukaran hadiah hadiah anak bray
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

                        // Sisa poin aktif yang sinkron mutlak di kalender mana pun gaes!
                        int sisaPoinAnak = totalPoinKumulatifMurni - totalPoinDitukar;
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

                              // GRID STATISTIK AKTIVITAS HARIAN (BERUBAH MENGIKUTI WAKTU SLIDER)
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.3,
                                children: [
                                  _buildStatCard('Total Tugas', '$totalTugas', Colors.blue),
                                  _buildStatCard('Selesai', '$tugasSelesai', Colors.green),
                                  _buildStatCard('Belum Selesai', '$tugasBelumSelesai', Colors.red.shade700),
                                ],
                              ),
                              const SizedBox(height: 24),

                              const Text(
                                'Neraca & Segmentasi Poin Anak ⭐',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 12),

                              // GRID NERACA POIN GLOBAL (TETAP DAN KOKOH DI TANGGAL MANAPUN BRAY)
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.1,
                                children: [
                                  _buildStatCard('Total Poin\n(Akumulasi)', '$totalPoinKumulatifMurni', Colors.purple),
                                  _buildStatCard('Poin Ditukar\n(Hadiah)', '$totalPoinDitukar', Colors.red.shade700),
                                  _buildStatCard('Sisa Poin\n(Aktif)', '$sisaPoinAnak 🔥', Colors.amber.shade900),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Daftar Status Riwayat Tugas 📋',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Tgl: $_tanggalTerpilihText',
                                    style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),

                              // LIST VIEW REKAM TANGGAL JALUR FILTERING
                              (!targetHariIniTerpilih && historyDocsHariTerpilih.isEmpty)
                                  ? const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Text('Tidak ada riwayat pengerjaan tugas di tanggal ini. 🛌'),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: targetHariIniTerpilih ? masterTasks.length : historyDocsHariTerpilih.length,
                                      itemBuilder: (context, index) {
                                        Map<String, dynamic> dataMap;
                                        String currentTaskId;

                                        if (targetHariIniTerpilih) {
                                          dataMap = masterTasks[index].data() as Map<String, dynamic>;
                                          currentTaskId = dataMap['taskId'] ?? masterTasks[index].id;
                                        } else {
                                          dataMap = historyDocsHariTerpilih[index].data() as Map<String, dynamic>;
                                          currentTaskId = dataMap['taskId'] ?? '';
                                        }

                                        final namaTugas = dataMap['namaTugas'] ?? dataMap['nama'] ?? 'Tanpa Nama';
                                        final num rawPoinList = dataMap['poin'] ?? 0;
                                        final int poin = rawPoinList.toInt();
                                        final String jenis = dataMap['jenis'] ?? 'Primer';

                                        String statusText = 'Belum Selesai';
                                        Color badgeColor = Colors.grey.shade200;
                                        Color textColor = Colors.grey.shade700;

                                        if (targetHariIniTerpilih) {
                                          // Lokalisasi pencarian status hari ini dari allHistoryDocs
                                          final pencarianLog = allHistoryDocs.where((d) => 
                                            (d.data() as Map<String, dynamic>)['taskId'] == currentTaskId &&
                                            (d.data() as Map<String, dynamic>)['tanggalLog'] == hariIniText
                                          );
                                          if (pencarianLog.isNotEmpty) {
                                            final hStatus = (pencarianLog.first.data() as Map<String, dynamic>)['status'] ?? 'Menunggu Verifikasi';
                                            if (hStatus == 'Selesai') {
                                              statusText = 'Finish 🎉';
                                              badgeColor = Colors.green.shade100;
                                              textColor = Colors.green.shade700;
                                            } else if (hStatus == 'Menunggu Verifikasi') {
                                              statusText = 'Menunggu Cek ⏳';
                                              badgeColor = Colors.orange.shade100;
                                              textColor = Colors.orange.shade700;
                                            }
                                          }
                                        } else {
                                          final hStatus = dataMap['status'] ?? 'Selesai';
                                          if (hStatus == 'Selesai') {
                                            statusText = 'Finish 🎉';
                                            badgeColor = Colors.green.shade100;
                                            textColor = Colors.green.shade700;
                                          } else if (hStatus == 'Menunggu Verifikasi') {
                                            statusText = 'Menunggu Cek ⏳';
                                            badgeColor = Colors.orange.shade100;
                                            textColor = Colors.orange.shade700;
                                          }
                                        }

                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          child: ListTile(
                                            leading: const CircleAvatar(
                                              backgroundColor: Colors.indigo,
                                              child: Icon(Icons.assignment, color: Colors.white),
                                            ),
                                            title: Text(
                                              namaTugas,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text('+$poin Poin • Jenis: $jenis'),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                );
              },
            ),
          ),
        ],
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