import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- Diperlukan untuk instance sekunder
import '../data/database_service.dart';
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
  final bool _isSaving = false;

  // Controller baru khusus untuk form pendaftaran akun anak
  final _namaAnakController = TextEditingController();
  final _emailAnakController = TextEditingController();
  final _passwordAnakController = TextEditingController();
  bool _isRegisteringAnak = false;

  // State pendukung untuk melacak pilihan jenis tugas di dialog bray
  bool _dialogIsRutin = true;

  // =========================================================================
  // FUNGSI SAKTI: DAFTAR ANAK TANPA LOGOUT AKUN ORTU (INSTANCE SEKUNDER)
  // =========================================================================
  Future<void> _eksekusiDaftarAkunAnak({
    required String namaAnak,
    required String emailAnak,
    required String passwordAnak,
    required String parentId,
  }) async {
    String nameInstance = "RegisterAnakInstance";
    FirebaseApp appSekunder;

    try {
      appSekunder = Firebase.app(nameInstance);
    } catch (_) {
      appSekunder = await Firebase.initializeApp(
        name: nameInstance,
        options: Firebase.app().options,
      );
    }

    FirebaseAuth authSekunder = FirebaseAuth.instanceFor(app: appSekunder);

    try {
      UserCredential result = await authSekunder.createUserWithEmailAndPassword(
        email: emailAnak.trim(),
        password: passwordAnak.trim(),
      );

      String? uidAnakBaru = result.user?.uid;

      if (uidAnakBaru != null) {
        // Tanam data ke Firestore dengan melampirkan parentId secara otomatis
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uidAnakBaru)
            .set({
              'uid': uidAnakBaru,
              'nama': namaAnak.trim(),
              'peran': 'Anak',
              'totalPoin': 0,
              'parentId': parentId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
      await authSekunder.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // DIALOG FORM PENDAFTARAN AKUN ANAK (METODE B)
  // =========================================================================
  void _tambahAnakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Daftarkan Akun Anak 👶✨'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _namaAnakController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Panggilan Anak',
                      ),
                    ),
                    TextField(
                      controller: _emailAnakController,
                      decoration: const InputDecoration(
                        labelText: 'Email Login Anak',
                        hintText: 'ex: anakbudi@gmail.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: _passwordAnakController,
                      decoration: const InputDecoration(
                        labelText: 'Password Akun Anak',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isRegisteringAnak
                      ? null
                      : () {
                          _namaAnakController.clear();
                          _emailAnakController.clear();
                          _passwordAnakController.clear();
                          Navigator.pop(context);
                        },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isRegisteringAnak
                      ? null
                      : () async {
                          if (_namaAnakController.text.isEmpty ||
                              _emailAnakController.text.isEmpty ||
                              _passwordAnakController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua kolom wajib diisi ya gaes!'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            _isRegisteringAnak = true;
                          });

                          try {
                            final String uidOrtuAktif =
                                _databaseService.currentUid ?? '';

                            await _eksekusiDaftarAkunAnak(
                              namaAnak: _namaAnakController.text,
                              emailAnak: _emailAnakController.text,
                              passwordAnak: _passwordAnakController.text,
                              parentId: uidOrtuAktif,
                            );

                            _namaAnakController.clear();
                            _emailAnakController.clear();
                            _passwordAnakController.clear();

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(
                                  'Akun Anak berhasil dibuat! Silakan login di HP anak 🥳',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text('Gagal: $e'),
                              ),
                            );
                          } finally {
                            setDialogState(() {
                              _isRegisteringAnak = false;
                            });
                          }
                        },
                  child: _isRegisteringAnak
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Daftarkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // UPDATE SEMPURNA: FORM DIALOG TUGAS BARU DENGAN CENTANG RUTIN VS SEKUNDER
  // =========================================================================
  void _tambahTugasDialog() {
    _dialogIsRutin = true; // Reset default centang selalu aktif saat dibuka bray

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Buat Tugas Baru 📝'),
            content: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 16),

                  // WIDGET INTERAKTIF SAKLAR TUGAS RUTIN VS SEKUNDER GAES ✨
                  Container(
                    decoration: BoxDecoration(
                      color: _dialogIsRutin ? Colors.indigo.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _dialogIsRutin ? Colors.indigo.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        _dialogIsRutin ? '🔄 Tugas Rutin Harian' : '⚡ Tugas Sekunder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _dialogIsRutin ? Colors.indigo.shade900 : Colors.orange.shade900,
                        ),
                      ),
                      subtitle: Text(
                        _dialogIsRutin
                            ? 'Otomatis muncul lagi besok hari bray.'
                            : 'Sekali pengerjaan langsung hangus hilang.',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                      value: _dialogIsRutin,
                      activeColor: Colors.indigo,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _dialogIsRutin = value ?? true;
                        });
                      },
                    ),
                  ),
                ],
              ),
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
                        if (_namaController.text.isNotEmpty &&
                            _poinController.text.isNotEmpty) {
                          Navigator.pop(context);
                          try {
                            final String uidOrangTua =
                                _databaseService.currentUid ?? '';
                            
                            // Mengirimkan isRutin ke DatabaseService agar sinkron total bray!
                            await _databaseService.tambahTugasBaru(
                              namaTugas: _namaController.text,
                              deskripsi: _dialogIsRutin ? 'Tugas rutin harian anak' : 'Tugas sekunder insidental',
                              kategori: _dialogIsRutin ? 'Rutinitas' : 'Sekunder',
                              poin: int.parse(_poinController.text),
                              wajibFoto: false,
                              parentId: uidOrangTua,
                              isRutin: _dialogIsRutin, 
                            );
                            
                            _namaController.clear();
                            _poinController.clear();

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_dialogIsRutin 
                                    ? 'Tugas Rutin Harian sukses ditambahkan! 🔄' 
                                    : 'Tugas Sekunder Sekali Pakai sukses ditambahkan! ⚡'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e')),
                            );
                          }
                        }
                      },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Menghilangkan bayangan kaku agar flat design kekinian
        elevation: 0, 
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        
        // =========================================================================
        // LOGO + TEXT BRANDING: BINTANG PARENTS GENERATION GAES ✨
        // =========================================================================
        title: Row(
          children: [
            // Kontainer Icon Logo Bintang bergaya modern/lembut
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50), // Efek glassmorphism halus (menggantikan .withOpacity)
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_twighlight, // Icon bintang terbit/fajar yang estetik
                color: Colors.amber, 
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            
            // Teks Kombinasi Dua Warna yang Ciamik
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sans', // Menyelaraskan dengan font bawaan bray
                ),
                children: [
                  TextSpan(
                    text: 'Bintang ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Parents',
                    style: TextStyle(color: Colors.amber), // Sentuhan warna emas ramah anak
                  ),
                ],
              ),
            ),
          ],
        ),
        
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
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
                    Expanded(
                      child: Column(
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
                            'Status: Akun Terhubung Aktif',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
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
                  Icons.person_add,
                  'Tambah Akun Anak',
                  Colors.pink,
                  _tambahAnakDialog,
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
                  Icons.thumb_up_alt,
                  'Persetujuan Hadiah',
                  Colors.amber.shade800,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerifikasiHadiahPage(),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        stream: _databaseService.dapatkanStreamVerifikasiTugas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Belum ada tugas menunggu verifikasi. 🌟'),
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
              final String anakUid = data['submittedBy'] ?? '';

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
                        await _databaseService.verifikasiTugasAnak(
                          taskId,
                          poin,
                          anakUid,
                        );

                        final String tanggalHariIni = DateTime.now()
                            .toIso8601String()
                            .substring(0, 10);
                        final String historyId = '${taskId}_$tanggalHariIni';

                        await FirebaseFirestore.instance
                            .collection('task_history')
                            .doc(historyId)
                            .update({
                              'status': 'Selesai',
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tugas Berhasil Diverifikasi! Laporan & Poin sinkron total 💸',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal verifikasi: $e')),
                        );
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

class VerifikasiHadiahPage extends StatefulWidget {
  const VerifikasiHadiahPage({super.key});

  @override
  State<VerifikasiHadiahPage> createState() => _VerifikasiHadiahPageState();
}

class _VerifikasiHadiahPageState extends State<VerifikasiHadiahPage> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final String currentParentUid = _databaseService.currentUid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Klaim Hadiah'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rewards')
            .where('parentId', isEqualTo: currentParentUid)
            .where('status', isEqualTo: 'Menunggu Persetujuan')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Belum ada klaim hadiah yang perlu disetujui. 🎁✨'),
              ),
            );
          }

          final listKlaimHadiah = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listKlaimHadiah.length,
            itemBuilder: (context, index) {
              final doc = listKlaimHadiah[index];
              final data = doc.data() as Map<String, dynamic>;

              final rewardId = data['rewardId'] ?? '';
              final namaHadiah = data['nama'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.redeem, color: Colors.white),
                  ),
                  title: Text(
                    namaHadiah,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Biaya: ${data['hargaPoin'] ?? 0} Poin ⭐'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        final dataReward = doc.data() as Map<String, dynamic>; 
                        final String anakUid = dataReward['anakUid'] ?? '';
                        final num hargaPoinRaw = dataReward['hargaPoin'] ?? 0;
                        final int hargaPoin = hargaPoinRaw.toInt();

                        await FirebaseFirestore.instance
                            .collection('rewards')
                            .doc(rewardId)
                            .update({
                              'status': 'Selesai Diklaim',
                              'approvedAt': FieldValue.serverTimestamp(),
                            });

                        if (anakUid.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(anakUid)
                              .update({
                                'totalPoin': FieldValue.increment(-hargaPoin),
                              });
                        }

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Hadiah sukses disetujui! Saldo bintang anak otomatis berkurang 🎁',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyetujui klaim: $e')),
                        );
                      }
                    },
                    child: const Text('Serahkan'),
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