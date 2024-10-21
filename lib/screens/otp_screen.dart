import 'package:flutter/material.dart';
import 'dart:math';  // Untuk menghasilkan OTP acak
import 'home_screen.dart';  // Import HomeScreen

class OtpScreen extends StatefulWidget {
  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String generatedOtp = '';
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _generateFakeOtp();  // Hasilkan OTP fiktif ketika layar dibuka
  }

  // Fungsi untuk menghasilkan OTP acak (6 digit)
  void _generateFakeOtp() {
    Random random = Random();
    generatedOtp = '';
    for (int i = 0; i < 6; i++) {
      generatedOtp += random.nextInt(10).toString();  // Hasilkan angka acak 0-9
    }

    // Tampilkan OTP fiktif di layar untuk tujuan simulasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode OTP fiktif: $generatedOtp'),
          duration: Duration(seconds: 10),  // Durasi diperpanjang menjadi 10 detik
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Masukkan kode OTP Anda',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            _buildOtpFields(),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                String otpCode = _getOtpCode();
                if (otpCode == generatedOtp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('OTP Berhasil Diverifikasi!')),
                  );

                  // Pindahkan ke HomeScreen setelah OTP berhasil diverifikasi
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('OTP Salah, coba lagi!')),
                  );
                }
              },
              child: Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan kolom kode OTP dengan tampilan kotak
  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.deepPurple, width: 2),
          ),
          child: TextFormField(
            controller: _otpControllers[index],
            autofocus: index == 0 ? true : false,  // Fokus otomatis pada kotak pertama
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (value.length == 1 && index < 5) {
                // Pindah fokus ke kolom berikutnya setelah input
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                // Kembali ke kolom sebelumnya jika kosong
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  // Menggabungkan semua kode OTP yang diinput
  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  @override
  void dispose() {
    // Bersihkan semua controller saat halaman ditutup
    _otpControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
