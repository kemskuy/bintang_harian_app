import 'package:flutter/material.dart';
import 'package:bintang_harian_app/data/auth_service.dart'; // Sesuaikan dengan nama package Anda

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Inisialisasi Service dan Controller
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Fungsi Eksekusi Login
  void _prosesLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var user = await _authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Jika login sukses, arahkan ke Pilih Peran (Mockup 3)
        Navigator.pushReplacementNamed(context, '/pilih-peran');
      }
    } on Exception catch (e) {
      if (mounted) {
        // Tampilkan pesan error jika gagal (misal: password salah / user tidak ditemukan)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) // Menampilkan loading saat proses
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... Sisi UI Header Anda (Logo / Gambar "Selamat Datang!") ...
                
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                
                // TOMBOL MASUK EMAIL
                ElevatedButton(
                  onPressed: _prosesLogin,
                  child: const Text('Masuk dengan Email'),
                ),
                
                // ... Tombol Google & Daftar Akun Baru ...
              ],
            ),
          ),
    );
  }
}