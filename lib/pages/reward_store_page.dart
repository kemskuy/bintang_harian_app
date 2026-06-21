import 'package:flutter/material.dart';
import '../data/data_hadiah.dart';
import '../data/data_tugas.dart';

class RewardStorePage extends StatefulWidget {
  const RewardStorePage({super.key});

  @override
  State<RewardStorePage> createState() => _RewardStorePageState();
}

class _RewardStorePageState extends State<RewardStorePage> {
  @override
  Widget build(BuildContext context) {
    // 1. Hitung total poin murni dari tugas yang sudah diverifikasi ortu
    int totalPoinMurni = DataTugas.daftarTugas
        .where((t) => t.selesai && t.diverifikasi)
        .fold(0, (sum, item) => sum + item.poin);

    // 2. Kurangi dengan total poin hadiah yang sudah ditukarkan anak
    int totalPoinDiterka = DataHadiah.katalogHadiah
        .where((h) => h.sudahDitebus)
        .fold(0, (sum, item) => sum + item.hargaPoin);

    int sisaPoinAnak = totalPoinMurni - totalPoinDiterka;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Hadiah Bintang 🎁'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner Sisa Poin Anda
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
                  'Sisa Bintangmu: $sisaPoinAnak Poin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: DataHadiah.katalogHadiah.length,
              itemBuilder: (context, index) {
                final hadiah = DataHadiah.katalogHadiah[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      hadiah.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${hadiah.hargaPoin} Bintang ⭐'),
                    trailing: hadiah.sudahDitebus
                        ? const Text(
                            'Sudah Ditukar ✔️',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: sisaPoinAnak >= hadiah.hargaPoin
                                ? () {
                                    setState(() {
                                      hadiah.sudahDitebus = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Hore! Sukses menukar ${hadiah.nama}! Laporkan ke Ortu ya! 🎉',
                                        ),
                                      ),
                                    );
                                  }
                                : null, // Tombol mati otomatis jika poin tidak cukup
                            child: const Text('Tukar'),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
