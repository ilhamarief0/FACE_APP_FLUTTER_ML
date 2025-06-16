import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faceabsensiapp/screens/home_page.dart';
import 'package:faceabsensiapp/api/auth_api.dart'; // Import AuthApi

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  final AuthApi _authApi = AuthApi(); // Inisialisasi AuthApi

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final responseData = await _authApi.login(username, password);

      final String? token = responseData['access_token'];
      final String? name = responseData['name'];
      final int? idUser = responseData['id_user'];
      final String? isFaceRecorded = responseData['is_face_recorded'];

      if (token != null && name != null && idUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('user_name', name);
        await prefs.setString('user_id', idUser.toString());
        await prefs.setString('is_face_recorded', isFaceRecorded ?? 'no');

        _showSnackBar('Login Berhasil!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showSnackBar('Login Gagal: Data tidak lengkap', Colors.red);
      }
    } catch (e) {
      _showSnackBar('${e.toString().replaceFirst('Exception: ', '')}', Colors.red);
      print('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Image.network(
                  'https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEhxbt-SEw8JiUsYl-GRs8hykZzxhosYvbGUarF1S6XqTyOr-zSg8owoMo2H652mccgB1CrEt0SVVOMtMTWvB3jLIBeojw7hTwAtHYBuQFJaNWx_qImHIl690GdHQEZPBebuTkMSp8O0zwuX502ov_jdfWRVV9e5iQEtq4m9QeNN5Ld8kBdWgzCXQg/w314-h320/Universitas%20Halu%20Oleo%20(KoleksiLogo.com).png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 120, color: Colors.grey);
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  'Selamat Datang di Absensi Mahasiswa ILKOM UHO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Silakan masuk dengan akun Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'NIM atau Username',
                    hintText: 'Masukkan NIM atau username Anda',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.indigo.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NIM atau Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.indigo.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.indigo.shade400,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureText,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.indigo.shade700))
                    : SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    _showSnackBar('Fitur Lupa Password belum diimplementasikan!', Colors.orange);
                  },
                  child: Text(
                    'Lupa Password?',
                    style: TextStyle(color: Colors.indigo.shade600, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
