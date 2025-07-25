import 'package:flutter/material.dart';
import 'package:hayami_app/Dashboard/dashboardposscreens.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/Login/forget.dart';
import 'package:hayami_app/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
 
void _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Username dan password wajib diisi.")),
    );
    return;
  }

  setState(() => _isLoading = true);

  // 🔄 Coba login ke POS API terlebih dahulu
  final response = await PosApiService.loginUser(email, password);

  if (response['status'] == 'success') {
    await _saveUserPrefs(response['user']);
    setState(() => _isLoading = false);

    // Slide transition for DashboardScreenPos
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreenPos(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide transition from right to left with smooth curve
          const begin = Offset(1.0, 0.0);  // Slide from the right
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          // Control the speed and easing using a custom tween
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),  // Increased transition duration
      ),
    );
    return;
  }

  // 🔁 Jika POS gagal, coba login ke Gudang API
  final gudangResponse = await GudangApiService.loginUser(email, password);

  setState(() => _isLoading = false);

  if (gudangResponse['status'] == 'success') {
    await _saveUserPrefs(gudangResponse['user']);

    // Slide transition for Dashboardscreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Dashboardscreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide transition from right to left with smooth curve
          const begin = Offset(1.0, 0.0);  // Slide from the right
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          // Control the speed and easing using a custom tween
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),  // Increased transition duration
      ),
    );
  } else {
    // ❌ Keduanya gagal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          gudangResponse['message'] ?? response['message'] ?? 'Login gagal.',
        ),
      ),
    );
  }
}

  Future<void> _saveUserPrefs(Map<String, dynamic> user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_user', user['id_user'] ?? '');
    await prefs.setString('nm_user', user['nm_user'] ?? '');
    await prefs.setString('jabatan', user['jabatan'] ?? '');
    await prefs.setString('email_user', user['email_user'] ?? '');
    await prefs.setString('no_telp', user['no_telp'] ?? ''); 
    await prefs.setString('alamat', user['alamat'] ?? '');
    await prefs.setString('karyawan', user['karyawan'] ?? '');
    await prefs.setString('grup', user['grup'] ?? '');
    await prefs.setString('id_cabang', user['id_cabang'] ?? '');
    await prefs.setString('id_gudang', user['id_gudang'] ?? '');
    await prefs.setString('sts', user['sts'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final paddingHorizontal = isTablet ? size.width * 0.2 : 20.0;
    final logoHeight = isTablet ? 100.0 : 60.0;
    final containerHeight = isTablet ? 300.0 : 200.0;
    final fontSize = isTablet ? 20.0 : 14.0;
    final buttonHeight = isTablet ? 60.0 : 50.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: containerHeight,
                width: double.infinity,
                padding: EdgeInsets.only(
                    top: isTablet ? 70 : 50, left: 10, right: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/image/hayamilogo.png',
                        height: logoHeight,
                      ),
                    ),
                    SizedBox(height: isTablet ? 30 : 20),
                    Text(
                      'Silakan masukkan Username dan Password\nuntuk masuk ke Hayami.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 40 : 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(fontSize: fontSize),
                    ),
                    SizedBox(height: isTablet ? 24 : 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(fontSize: fontSize),
                    ),
                    SizedBox(height: isTablet ? 16 : 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LupaPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Lupa password?",
                          style: TextStyle(fontSize: fontSize * 0.9),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, buttonHeight),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                "MASUK",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}