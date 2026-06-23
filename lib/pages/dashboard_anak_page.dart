import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/database_service.dart';
import 'reward_store_page.dart';

class DashboardAnakPage extends StatefulWidget {
  const DashboardAnakPage({super.key});

  @override
  State<DashboardAnakPage> createState() => _DashboardAnakPageState();
}

class _DashboardAnakPageState extends State<DashboardAnakPage> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final String currentAnakUid = _databaseService.currentUid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Anak'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              await FirebaseAuth.instance.signOut();
              await FirebaseFirestore.instance.clearPersistence();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _databaseService.dapatkanDataUserAktif(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final String parentId = userData?['parentId'] ?? '';
          final int totalPoin = userData?['totalPoin'] ?? 0;

          // Stream Utama Tugas Master dari Ortu
          return StreamBuilder<QuerySnapshot>(
            stream: _databaseService.dapatkanStreamTugasBerdasarParent(parentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final masterTasks = snapshot.data?.docs ?? [];
              
              // Waktu lokal HP anak untuk patokan saklar reset bray
              final String tanggalHariIni = DateTime.now().toIso8601String().substring(0, 10);

              // Stream Pendukung: Ambil rekam jejak history untuk kalkulasi status dinamis
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('task_history')
                    .where('anakUid', isEqualTo: currentAnakUid)
                    .snapshots(),
                builder: (context, historySnapshot) {
                  if (historySnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final historyDocs = historySnapshot.data?.docs ?? [];

                  // Map untuk memantau status pengerjaan khusus HARI INI SAJA bray
                  Map<String, String> statusHistoryHariIni = {};
                  
                  // List khusus menampung ID tugas sekunder yang dikerjakan DI MASA LALU (sebelum hari ini)
                  List<String> sekunderMasaLaluSelesai = [];

                  for (var hDoc in historyDocs) {
                    final hData = hDoc.data() as Map<String, dynamic>;
                    final String tId = hData['taskId'] ?? '';
                    final String tglLog = hData['tanggalLog'] ?? '';
                    final String hStatus = hData['status'] ?? 'Menunggu Verifikasi';
                    final String jenisTugas = hData['jenis'] ?? 'Rutin';

                    if (tglLog == tanggalHariIni) {
                      statusHistoryHariIni[tId] = hStatus;
                    }

                    // KUNCI UTAMA: Tugas sekunder baru ditandai "tamat" jika tanggal log-nya BUKAN hari ini bray!
                    if (jenisTugas == 'Sekunder' && tglLog != tanggalHariIni) {
                      sekunderMasaLaluSelesai.add(tId);
                    }
                  }

                  // --- PROSES FILTER SEPARASI TUGAS RUTIN VS SEKUNDER ---
                  List<QueryDocumentSnapshot> tugasTampilHariIni = [];

                  for (var taskDoc in masterTasks) {
                    final taskData = taskDoc.data() as Map<String, dynamic>;
                    final String taskId = taskData['taskId'] ?? taskDoc.id;
                    final bool isRutin = taskData['isRutin'] ?? (taskData['jenis'] == 'Rutin');

                    if (isRutin) {
                      // JIKA TUGAS RUTIN: Selalu lolos tampil setiap hari bray bray
                      tugasTampilHariIni.add(taskDoc);
                    } else {
                      // JIKA TUGAS SEKUNDER: Hanya disembunyikan jika sudah selesai di hari-hari kemarin!
                      // Kalau baru diklik hari ini, dia TIDAK AKAN masuk list masa lalu, jadi tetep nongol!
                      if (!sekunderMasaLaluSelesai.contains(taskId)) {
                        tugasTampilHariIni.add(taskDoc);
                      }
                    }
                  }

                  // Hitung ringkasan statistik beranda anak hari ini
                  int totalTugas = tugasTampilHariIni.length;
                  int tugasSelesai = 0;

                  for (var taskDoc in tugasTampilHariIni) {
                    final taskData = taskDoc.data() as Map<String, dynamic>;
                    final String taskId = taskData['taskId'] ?? taskDoc.id;
                    if (statusHistoryHariIni.containsKey(taskId)) {
                      final s = statusHistoryHariIni[taskId];
                      if (s == 'Selesai') {
                        tugasSelesai++;
                      }
                    }
                  }

                  double persentaseSelesai = totalTugas > 0 ? (tugasSelesai / totalTugas) * 100 : 0.0;

                  // Pengurutan daftar tugas hari ini berdasarkan waktu dibuat
                  List<QueryDocumentSnapshot> sortedTugas = List.from(tugasTampilHariIni);
                  sortedTugas.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTimestamp = aData['createdAt'] as Timestamp?;
                    final bTimestamp = bData['createdAt'] as Timestamp?;
                    if (aTimestamp == null || bTimestamp == null) return 0;
                    return bTimestamp.compareTo(aTimestamp);
                  });

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 105,
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.amber,
                                      radius: 16,
                                      child: Icon(Icons.stars, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Poin Kamu',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$totalPoin',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniStatCard(
                                      'Total Tugas',
                                      '$totalTugas',
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildMiniStatCard(
                                      'Progres',
                                      '${persentaseSelesai.toStringAsFixed(0)}%',
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tugas Hari Ini 📝',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amber.shade900,
                                backgroundColor: Colors.amber.shade100,
                              ),
                              icon: const Icon(Icons.store, size: 18),
                              label: const Text('Toko Hadiah 🎁', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RewardStorePage()),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        sortedTugas.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'Hore! Tidak ada tugas aktif hari ini bray. 🛌✨',
                                    style: TextStyle(color: Colors.black45),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedTugas.length,
                                itemBuilder: (context, index) {
                                  final doc = sortedTugas[index];
                                  final data = doc.data() as Map<String, dynamic>;

                                  final taskId = data['taskId'] ?? doc.id;
                                  final namaTugas = data['namaTugas'] ?? '';
                                  final kategori = data['kategori'] ?? 'Rutinitas';
                                  final poin = data['poin'] ?? 0;
                                  final bool isRutin = data['isRutin'] ?? (data['jenis'] == 'Rutin');

                                  // Baca status secara dinamis dari map history log hari ini bray
                                  String statusTugasHariIni = 'Aktif';
                                  if (statusHistoryHariIni.containsKey(taskId)) {
                                    statusTugasHariIni = statusHistoryHariIni[taskId]!;
                                  }

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: statusTugasHariIni == 'Selesai'
                                            ? Colors.green
                                            : (statusTugasHariIni == 'Menunggu Verifikasi'
                                                ? Colors.orange
                                                : Colors.amber),
                                        child: const Icon(Icons.star, color: Colors.white),
                                      ),
                                      title: Text(
                                        namaTugas,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Jenis: ${isRutin ? "Rutin" : "Sekunder"} • +$poin Poin ⭐',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: statusTugasHariIni == 'Aktif'
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.indigo,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              onPressed: () async {
                                                try {
                                                  // 1. Update status tugas utama hari ini di database bray
                                                  await FirebaseFirestore.instance
                                                      .collection('tasks')
                                                      .doc(taskId)
                                                      .update({
                                                    'status': 'Menunggu Verifikasi',
                                                    'submittedBy': currentAnakUid,
                                                    'submittedAt': FieldValue.serverTimestamp(),
                                                  });

                                                  // 2. Kunci log di task_history beserta snapshot totalTugas untuk laporan ortu bray bray
                                                  await FirebaseFirestore.instance
                                                      .collection('task_history')
                                                      .doc('${taskId}_$tanggalHariIni')
                                                      .set({
                                                    'historyId': '${taskId}_$tanggalHariIni',
                                                    'taskId': taskId,
                                                    'namaTugas': namaTugas,
                                                    'kategori': kategori,
                                                    'poin': poin,
                                                    'status': 'Menunggu Verifikasi',
                                                    'jenis': isRutin ? 'Rutin' : 'Sekunder',
                                                    'anakUid': currentAnakUid,
                                                    'parentId': parentId,
                                                    'tanggalLog': tanggalHariIni,
                                                    'totalTugasHariIni': totalTugas, 
                                                    'updatedAt': FieldValue.serverTimestamp(),
                                                  });

                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Tugas "$namaTugas" terkirim! Log hari ini tercatat ⏳')),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Gagal: $e')),
                                                  );
                                                }
                                              },
                                              child: const Text('Selesai'),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: statusTugasHariIni == 'Selesai'
                                                    ? Colors.green.shade100
                                                    : Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                statusTugasHariIni == 'Selesai' ? 'Finish 🎉' : 'Menunggu Cek ⏳',
                                                style: TextStyle(
                                                  color: statusTugasHariIni == 'Selesai'
                                                      ? Colors.green.shade800
                                                      : Colors.orange.shade800,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildMiniStatCard(String title, String value, Color color) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}