import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart';

class RewardStorePage extends StatefulWidget {
  const RewardStorePage({super.key});

  @override
  State<RewardStorePage> createState() => _RewardStorePageState();
}

class _RewardStorePageState extends State<RewardStorePage> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final String currentAnakUid = _databaseService.currentUid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Hadiah Bintang 🎁'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      // STREAM 1: Ambil saldo 'totalPoin' asli anak secara real-time
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentAnakUid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          int totalPoinAnak = userData?['totalPoin'] ?? 0;
          String parentId = userData?['parentId'] ?? '';

          return Column(
            children: [
              // Banner Sisa Poin Anda (Mengambil dari saldo totalPoin Firestore)
              Container(
                width: double.infinity,
                color: Colors.amber.shade100,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      'Sisa Bintangmu: $totalPoinAnak Poin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              
              // STREAM 2: Ambil katalog hadiah yang dibuat oleh Ortu (berdasar parentId)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _databaseService.dapatkanStreamHadiahBerdasarParent(parentId),
                  builder: (context, rewardSnapshot) {
                    if (rewardSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!rewardSnapshot.hasData || rewardSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('Belum ada hadiah tersedia dari Orang Tua. 🛒'),
                        ),
                      );
                    }

                    final listHadiah = rewardSnapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listHadiah.length,
                      itemBuilder: (context, index) {
                        final doc = listHadiah[index];
                        final hadiah = doc.data() as Map<String, dynamic>;

                        final rewardId = hadiah['rewardId'] ?? '';
                        final nama = hadiah['nama'] ?? '';
                        final hargaPoin = hadiah['hargaPoin'] ?? 0;
                        final status = hadiah['status'] ?? 'Tersedia';

                        bool sudahDitukar = status == 'Menunggu Persetujuan' || status == 'Selesai Diklaim';

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orangeAccent,
                              child: Icon(Icons.card_giftcard, color: Colors.white),
                            ),
                            title: Text(
                              nama,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('$hargaPoin Bintang ⭐'),
                            trailing: sudahDitukar
                                ? Text(
                                    status == 'Menunggu Persetujuan' ? 'Menunggu Ortu ⏳' : 'Sudah Ditukar ✔️',
                                    style: TextStyle(
                                      color: status == 'Menunggu Persetujuan' ? Colors.orange : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                    // Tombol aktif hanya jika poin anak cukup
                                    onPressed: totalPoinAnak >= hargaPoin
                                        ? () async {
                                            try {
                                              // Jalankan fungsi transaksi potong poin otomatis
                                              await _databaseService.tukarHadiah(
                                                rewardId: rewardId,
                                                hargaPoin: hargaPoin,
                                                anakUid: currentAnakUid,
                                              );

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Hore! Sukses menukar $nama! Tunggu persetujuan Ortu ya! 🎉')),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Gagal menukar: $e')),
                                                );
                                              }
                                            }
                                          }
                                        : null, // Otomatis disable jika poin kurang
                                    child: const Text('Tukar'),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}