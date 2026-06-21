import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // <-- TAMBAHKAN INI
import 'firebase_options.dart'; 
import 'data/database_service.dart'; // <-- TAMBAHKAN INI (Sesuaikan folder path Anda jika berbeda)

import 'pages/login_page.dart';
import 'pages/pilih_peran_page.dart';
import 'pages/dashboard_ortu_page.dart'; 
import 'pages/dashboard_anak_page.dart'; 
import 'pages/reward_store_page.dart';
import 'pages/kelola_hadiah_page.dart'; 
import 'pages/laporan_anak_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );

  runApp(const BintangHarianApp());
}

class BintangHarianApp extends StatelessWidget {
  const BintangHarianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bintang Harian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/pilih-peran': (context) => const PilihPeranPage(),
        '/dashboard-ortu': (context) => const DashboardOrtuPage(), 
        '/dashboard-anak': (context) => const DashboardAnakPage(), 
        '/reward-store': (context) => const RewardStorePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DatabaseService _dbService = DatabaseService(); // Inisialisasi DatabaseService

  @override
  void initState() {
    super.initState();
    _cekStatusNavigasi();
  }

  // LOGIKA PINTASAN OTOMATIS (AUTO-ROUTING)
  void _cekStatusNavigasi() async {
    // Beri jeda 3 detik untuk memperlihatkan animasi splash screen yang keren
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 1. Cek apakah ada user yang masih login di Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 2. Jika user sudah login, cek perannya yang tersimpan di Cloud Firestore
      String? peran = await _dbService.ambilPeranUser();

      if (mounted) {
        if (peran == 'Orang Tua') {
          Navigator.pushReplacementNamed(context, '/dashboard-ortu');
        } else if (peran == 'Anak') {
          Navigator.pushReplacementNamed(context, '/dashboard-anak');
        } else {
          // Jika sudah login tapi belum pilih peran
          Navigator.pushReplacementNamed(context, '/pilih-peran');
        }
      }
    } else {
      // 3. Jika belum login sama sekali, arahkan ke halaman Login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, size: 100, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'BINTANG HARIAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kebiasaan baik hari ini,\nmasa depan hebat nanti ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}