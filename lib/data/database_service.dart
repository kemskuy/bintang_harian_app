import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mengambil UID user yang sedang login
  String? get currentUid => _auth.currentUser?.uid;

  // Stream data profil user aktif
  Stream<DocumentSnapshot> dapatkanDataUserAktif() {
    return _db.collection('users').doc(currentUid ?? '').snapshots();
  }

  // Stream tugas berdasarkan parentId (Tanpa .orderBy agar tidak error index)
  Stream<QuerySnapshot> dapatkanStreamTugasBerdasarParent(String parentId) {
    return _db.collection('tasks')
        .where('parentId', isEqualTo: parentId)
        .snapshots();
  }

  // >>> TAMBAHKAN BARIS INI GAES KHUSUS UNTUK HALAMAN LAPORAN <<<
  Stream<QuerySnapshot> dapatkanStreamTugas() {
    return _db.collection('tasks').snapshots();
  }

  // Simpan atau perbarui peran
  Future<void> simpanPeranUser(String peran) async {
    if (currentUid != null) {
      await _db.collection('users').doc(currentUid).set({
        'uid': currentUid,
        'peran': peran, 
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Ambil peran user
  Future<String?> ambilPeranUser() async {
    if (currentUid != null) {
      DocumentSnapshot doc = await _db.collection('users').doc(currentUid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['peran'] as String?;
      }
    }
    return null;
  }

  // Tambah tugas baru dari Orang Tua
  Future<void> tambahTugasBaru({
    required String namaTugas,
    required String deskripsi,
    required String kategori,
    required int poin,
    required bool wajibFoto,
    required String parentId,
  }) async {
    if (currentUid != null) {
      DocumentReference taskDoc = _db.collection('tasks').doc();
      await taskDoc.set({
        'taskId': taskDoc.id,
        'createdBy': currentUid,       
        'namaTugas': namaTugas,
        'deskripsi': deskripsi,
        'kategori': kategori,
        'poin': poin,
        'wajibFoto': wajibFoto,
        'status': 'Aktif',             
        'parentId': parentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // =========================================================================
  // KELOMPOK FITUR HADIAH V1.1 (TERKONEKSI ANTAR AKUN)
  // =========================================================================

  // A. Tambah hadiah baru dengan menyertakan parentId keluarga
  Future<void> tambahHadiahBaru({
    required String nama, 
    required int hargaPoin,
    required String parentId, 
  }) async {
    if (currentUid != null) {
      DocumentReference rewardDoc = _db.collection('rewards').doc();
      await rewardDoc.set({
        'rewardId': rewardDoc.id,
        'createdBy': currentUid,
        'nama': nama,
        'hargaPoin': hargaPoin,
        'status': 'Tersedia', 
        'parentId': parentId, 
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // B. Stream untuk menarik katalog hadiah khusus keluarga tersebut
  Stream<QuerySnapshot> dapatkanStreamHadiahBerdasarParent(String parentId) {
    return _db.collection('rewards')
        .where('parentId', isEqualTo: parentId)
        .snapshots();
  }

  // C. Fungsi Potong Poin otomatis saat Anak menukarkan Hadiah
  Future<void> tukarHadiah({
    required String rewardId, 
    required int hargaPoin, 
    required String anakUid,
  }) async {
    final rewardRef = _db.collection('rewards').doc(rewardId);
    final userRef = _db.collection('users').doc(anakUid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) throw Exception("User anak tidak ditemukan!");
      
      int totalPoinAnak = (userSnapshot.data() as Map<String, dynamic>)['totalPoin'] ?? 0;

      if (totalPoinAnak < hargaPoin) {
        throw Exception("Poin kamu tidak cukup untuk menukar hadiah ini! 😢");
      }

      transaction.update(userRef, {
        'totalPoin': FieldValue.increment(-hargaPoin),
      });

      transaction.update(rewardRef, {
        'status': 'Menunggu Persetujuan',
        'claimedBy': anakUid,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Fungsi penyeimbang agar halaman lama tidak error
  Stream<QuerySnapshot> dapatkanStreamHadiah() {
    return _db.collection('rewards').snapshots();
  }

  Future<void> hapusHadiah(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }

  Stream<QuerySnapshot> dapatkanStreamVerifikasiTugas() {
    return _db.collection('tasks').where('status', isEqualTo: 'Menunggu Verifikasi').snapshots();
  }

  // VERIFIKASI VERSI DINAMIS V1.1: Menerima anakUid langsung dari data tugas pelapor
  Future<void> verifikasiTugasAnak(String taskId, int poinTugas, String anakUid) async {
    final taskRef = _db.collection('tasks').doc(taskId);
    
    // Alamat dokumen user diarahkan otomatis ke UID anak yang mengerjakan
    final userRef = _db.collection('users').doc(anakUid);

    await _db.runTransaction((transaction) async {
      // 1. Update status tugas menjadi Selesai
      transaction.update(taskRef, {
        'status': 'Selesai',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // 2. Tambahkan poin langsung ke saldo user Anak jika ID-nya terdeteksi ada
      if (anakUid.isNotEmpty) {
        transaction.update(userRef, {
          'totalPoin': FieldValue.increment(poinTugas),
        });
      }
    });
  }

  Future<void> ajukanSelesaiTugas(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'Menunggu Verifikasi',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }
}