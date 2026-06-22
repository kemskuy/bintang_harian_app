import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. KITA TAMBAHKAN IMPORT INI DI SINI BRAY!
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
              // 1. Ambil instance navigator duluan sebelum context-nya hangus
              final navigator = Navigator.of(context);

              // 2. Tendang user ke halaman login secara instan agar UI tidak freeze bray
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);

              // 3. Setelah UI aman di halaman login, baru putus sesi auth di background
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

          return StreamBuilder<QuerySnapshot>(
            stream: _databaseService.dapatkanStreamTugasBerdasarParent(
              parentId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final dokumenTugas = snapshot.data?.docs ?? [];

              int totalTugas = dokumenTugas.length;
              int tugasSelesai = dokumenTugas
                  .where(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['status'] ==
                        'Selesai',
                  )
                  .length;

              double persentaseSelesai = totalTugas > 0
                  ? (tugasSelesai / totalTugas) * 100
                  : 0.0;

              List<QueryDocumentSnapshot> sortedTugas = List.from(dokumenTugas);
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
                                  child: Icon(
                                    Icons.stars,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber.shade900,
                            backgroundColor: Colors.amber.shade100,
                          ),
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text(
                            'Toko Hadiah 🎁',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RewardStorePage(),
                              ),
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
                                'Belum ada tugas hari ini. ✨',
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
                                        : (status == 'Menunggu Verifikasi'
                                              ? Colors.orange
                                              : Colors.amber),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    namaTugas,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$kategori • $poin Poin Bintang ⭐',
                                  ),
                                  trailing: status == 'Aktif'
                                      ? ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('tasks')
                                                  .doc(taskId)
                                                  .update({
                                                    'status':
                                                        'Menunggu Verifikasi',
                                                    'submittedBy':
                                                        currentAnakUid,
                                                    'submittedAt':
                                                        FieldValue.serverTimestamp(),
                                                  });

                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Tugas "$namaTugas" dikirim ke Orang Tua! ⏳',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Gagal: $e'),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Selesai'),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: status == 'Selesai'
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: status == 'Selesai'
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
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
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
    );
  }
}
