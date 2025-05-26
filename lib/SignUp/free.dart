import 'package:flutter/material.dart';
import 'package:hayami_app/Login/loginScreen.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FreeRegis(),
  ));
}

class FreeRegis extends StatefulWidget {
  const FreeRegis({super.key});

  @override
  State<FreeRegis> createState() => _FreeRegis();
}

class _FreeRegis extends State<FreeRegis> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController couponController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _showCouponField = false;
  bool _isPasswordVisible = false; // Untuk mengontrol visibility password

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daftar!',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildTextField(Icons.person, "Nama lengkap", nameController),
                  const SizedBox(height: 16),
                  _buildTextField(
                      Icons.apartment, "Nama perusahaan", companyController),
                  const SizedBox(height: 16),
                  _buildTextField(
                      Icons.phone, "Nomor telepon", phoneController),
                  const SizedBox(height: 16),
                  _buildTextField(Icons.email, "Email", emailController),
                  const SizedBox(height: 16),
                  _buildPasswordField(), // Password Field with show/hide functionality
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showCouponField = !_showCouponField;
                        });
                      },
                      child: Text(
                        _showCouponField
                            ? 'Sembunyikan Kode Kupon'
                            : 'Masukkan Kode Kupon',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  if (_showCouponField)
                    _buildTextField(
                        Icons.card_giftcard, "Kode Kupon", couponController),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero, // Menghilangkan padding ekstra
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.transparent, // Transparan agar tidak ada area putih
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(
                              minWidth: double.infinity, minHeight: 50),
                          child: const Text(
                            "DAFTAR",
                            style: TextStyle(
                              color: Color.fromARGB(255, 243, 245, 247),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        var url = Uri.parse("http://192.168.1.10/connect/JSON/free.php");

                        // Tampilkan loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          var response = await http.post(url, body: {
                            "name": nameController.text,
                            "company": companyController.text,
                            "phone": phoneController.text,
                            "email": emailController.text,
                            "password": passwordController.text, // Password
                          });

                          Navigator.pop(context); // Tutup loading

                          String body = response.body.trim().toLowerCase();
                          print("Response status: ${response.statusCode}");
                          print("Response body: '$body'");

                          if (response.statusCode == 200 && body == "success") {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Pendaftaran Berhasil"),
                                content: const Text("Akun Anda berhasil dibuat. Silakan masuk."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginPage()),
                                      );
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Gagal Daftar"),
                                content: Text("Pesan dari server: ${response.body}"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context); // Tutup loading
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Error"),
                              content: Text("Terjadi kesalahan: $e"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Sudah punya akun? ',
                        children: [
                          TextSpan(
                            text: 'Masuk',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword, // Jika password, sembunyikan teks
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: const UnderlineInputBorder(),
      ),
    );
  }

  // Password field with Show/Hide toggle
  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: !_isPasswordVisible, // Menggunakan _isPasswordVisible
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock),
        hintText: "Password",
        border: const UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.blue,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
