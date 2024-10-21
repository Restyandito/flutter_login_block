import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';  // untuk Timer
import 'register_screen.dart';  // Pastikan jalur file benar
import 'otp_screen.dart';  // Pastikan jalur file benar

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isFirstLaunch = false;
  int _failedAttempts = 0;
  DateTime? _blockUntil;

  // Durasi pemblokiran dalam menit
  final int _blockDuration = 1;

  @override
  void initState() {
    super.initState();
    _checkIfRegistered();  // Memeriksa apakah sudah ada akun yang terdaftar
    _loadLoginData();  // Memuat data login saat pertama kali aplikasi diluncurkan
  }

  // Cek apakah sudah ada akun yang terdaftar
  Future<void> _checkIfRegistered() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String registeredEmail = prefs.getString('registeredEmail') ?? '';
    String registeredPassword = prefs.getString('registeredPassword') ?? '';

    if (registeredEmail.isEmpty || registeredPassword.isEmpty) {
      // Jika belum ada akun yang terdaftar, tampilkan pemberitahuan
      setState(() {
        _isFirstLaunch = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRegistrationPrompt();
      });
    }
  }

  // Pemberitahuan registrasi cepat
  void _showRegistrationPrompt() {
    final snackBar = SnackBar(
      content: Text('Belum ada akun, silakan registrasi!'),
      duration: Duration(milliseconds: 1500),  // Durasi lebih singkat
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Registrasi',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterScreen()),
          );
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Memuat data login dan percobaan gagal dari SharedPreferences
  Future<void> _loadLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _failedAttempts = prefs.getInt('failedAttempts') ?? 0;
      _blockUntil = prefs.getString('blockUntil') != null
          ? DateTime.tryParse(prefs.getString('blockUntil')!)
          : null;
    });

    // Jika waktu blokir sudah berlalu, reset percobaan gagal
    if (_blockUntil != null && DateTime.now().isAfter(_blockUntil!)) {
      await _resetFailedAttempts();
    }
  }

  Future<void> _saveLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('failedAttempts', _failedAttempts);
    if (_blockUntil != null) {
      await prefs.setString('blockUntil', _blockUntil!.toIso8601String());
    }
  }

  Future<void> _resetFailedAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _failedAttempts = 0;
      _blockUntil = null;
    });
    await prefs.remove('failedAttempts');
    await prefs.remove('blockUntil');
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String registeredEmail = prefs.getString('registeredEmail') ?? '';
    String registeredPassword = prefs.getString('registeredPassword') ?? '';

    // Cek apakah akun diblokir
    if (_blockUntil != null && DateTime.now().isBefore(_blockUntil!)) {
      final timeRemaining = _blockUntil!.difference(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun Anda diblokir, coba lagi dalam ${timeRemaining.inMinutes} menit.'),
          duration: Duration(milliseconds: 1500),  // Durasi lebih singkat
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (_emailController.text == registeredEmail &&
        _passwordController.text == registeredPassword) {
      // Jika login berhasil, reset percobaan gagal
      await _resetFailedAttempts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login berhasil!')),
      );

      // Arahkan ke layar OTP
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen()),
      );
    } else {
      // Jika login gagal, tingkatkan percobaan gagal
      setState(() {
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        // Blokir pengguna selama 15 menit jika gagal 3 kali
        setState(() {
          _blockUntil = DateTime.now().add(Duration(minutes: _blockDuration));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Login gagal 3 kali, akun Anda diblokir selama $_blockDuration menit.'),
            duration: Duration(milliseconds: 1500),  // Durasi lebih singkat
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Login gagal, Anda memiliki ${3 - _failedAttempts} percobaan tersisa.'),
            duration: Duration(milliseconds: 1500),  // Durasi lebih singkat
          ),
        );
      }

      // Simpan data percobaan login gagal dan waktu pemblokiran
      await _saveLoginData();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Text(
                      'Login',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Arahkan ke layar registrasi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Register',
                      style: TextStyle(color: Colors.deepPurpleAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
