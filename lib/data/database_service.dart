import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mengambil UID user yang sedang login
  String? get currentUid => _auth.currentUser?.uid;

  // 1. Fungsi untuk menyimpan atau memperbarui Peran User di Firestore
  Future<void> simpanPeranUser(String peran) async {
    if (currentUid != null) {
      await _db.collection('users').doc(currentUid).set({
        'uid': currentUid,
        'peran': peran, 
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // 2. Fungsi untuk mengambil data peran user saat ini
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

  // 3. Fungsi untuk menyimpan tugas baru dari Orang Tua ke Firestore
  Future<void> tambahTugasBaru({
    required String namaTugas,
    required String deskripsi,
    required String kategori,
    required int poin,
    required bool wajibFoto,
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
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 4. Stream untuk menarik data tugas secara real-time
  Stream<QuerySnapshot> dapatkanStreamTugas() {
    return _db.collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 5. Fungsi untuk menyimpan hadiah baru ke Firestore
  Future<void> tambahHadiahBaru({
    required String nama,
    required int hargaPoin,
  }) async {
    if (currentUid != null) {
      DocumentReference rewardDoc = _db.collection('rewards').doc();
      await rewardDoc.set({
        'rewardId': rewardDoc.id,
        'createdBy': currentUid,
        'nama': nama,
        'hargaPoin': hargaPoin,
        'sudahDitebus': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 6. Stream untuk memantau katalog hadiah secara real-time
  Stream<QuerySnapshot> dapatkanStreamHadiah() {
    return _db.collection('rewards')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 7. Fungsi untuk menghapus hadiah dari Firestore
  Future<void> hapusHadiah(String rewardId) async {
    await _db.collection('rewards').doc(rewardId).delete();
  }

// 8. Stream untuk menarik data tugas yang BUTUH VERIFIKASI (Selesai tapi belum diverifikasi)
  Stream<QuerySnapshot> dapatkanStreamVerifikasiTugas() {
    return _db.collection('tasks')
        .where('status', isEqualTo: 'Menunggu Verifikasi')
        .snapshots();
  }

  // 9. Fungsi untuk memverifikasi tugas sekaligus menambahkan poin ke user
  Future<void> verifikasiTugasAnak(String taskId, int poinTugas) async {
    // Kita gunakan batch/transaction agar jika salah satu gagal, semua dibatalkan (aman)
    final taskRef = _db.collection('tasks').doc(taskId);
    
    // Karena saat ini kita menggunakan satu akun/atau simplifikasi multi-role di dokumen profil yang sama:
    if (currentUid != null) {
      final userRef = _db.collection('users').doc(currentUid);

      await _db.runTransaction((transaction) async {
        // 1. Update status tugas
        transaction.update(taskRef, {
          'status': 'Selesai',
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        // 2. Tambahkan poin ke saldo user
        transaction.update(userRef, {
          'totalPoin': FieldValue.increment(poinTugas),
        });
      });
    }
  }

// 10. Fungsi untuk diajukan anak ketika tugas selesai dikerjakan
  Future<void> ajukanSelesaiTugas(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'Menunggu Verifikasi',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }
} // <-- Pastikan tanda kurung ini berada di paling bawah file!