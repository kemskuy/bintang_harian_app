import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Aliran Status Autentikasi (Stream)
  // Berfungsi untuk memantau apakah user sedang login atau tidak
  Stream<User?> get userStream => _auth.authStateChanges();

  // 2. Mendapatkan User yang sedang aktif saat ini
  User? get currentUser => _auth.currentUser;

  // 3. Logika Masuk dengan Email dan Password (Sesuai Mockup 2)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik dari Firebase
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow; // Melempar error ke UI agar bisa ditampilkan sebagai SnackBar
    } catch (e) {
      print("General Auth Error: ${e.toString()}");
      return null;
    }
  }

  // 4. Logika Daftar Akun Baru (Sesuai Mockup 2)
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Register Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("General Register Error: ${e.toString()}");
      return null;
    }
  }

  // 5. Logika Keluar (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}