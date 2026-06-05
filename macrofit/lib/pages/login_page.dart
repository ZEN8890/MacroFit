import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macrofit/services/auth_services.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _passwordIsVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final bool isEnglish = isEnglishNotifier.value;

    if (email.isEmpty || password.isEmpty) {
      Notify.error(
        context,
        isEnglish
            ? "Email and password cannot be empty"
            : "Email dan password harus diisi",
      );
      return;
    }

    setState(() => _isLoading = true);

    final String? result = await _authService.userLogin(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result == "success") {
      try {
        // 1. Dapatkan UID dari user yang baru saja berhasil login
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 2. Ambil snapshot datanya dari Cloud Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data() as Map<String, dynamic>;

            // 3. Ambil bendera status onboarding (default: false jika akun gres baru daftar)
            bool hasCompletedOnboarding =
                userData['has_completed_onboarding'] ?? false;

            if (mounted) setState(() => _isLoading = false);

            Notify.success(
              context,
              isEnglish ? "Login successful!" : "Login berhasil!",
            );

            await Future.delayed(const Duration(milliseconds: 500));
            if (!mounted) return;

            // 🟢 PERCABANGAN RUTE KRITIS:
            if (hasCompletedOnboarding) {
              // User Lama -> langsung lolos ke Home Screen Beranda Utama
              Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
            } else {
              // User Baru Pertama Kali Login -> Dipaksa belok ke halaman Onboarding
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/onboarding",
                (route) => false,
              );
            }
            return;
          }
        }
      } catch (dbError) {
        debugPrint("Gagal memeriksa status onboarding database: $dbError");
      }

      // Fallback aman jika pembacaan Firestore gagal, langsung ke Home
      if (mounted) setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    } else {
      if (mounted) setState(() => _isLoading = false);
      Notify.error(
        context,
        result == "Login gagal" && isEnglish
            ? "Login failed"
            : (result ?? "Login gagal"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Image.asset(
                            'assets/Macrofit_logo_only.png',
                            height: 120,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          englishActive ? "Welcome Back" : "Selamat Datang",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          englishActive
                              ? "Please sign in to continue"
                              : "Silakan masuk untuk melanjutkan",
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordIsVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _passwordIsVisible = !_passwordIsVisible,
                              ),
                              icon: Icon(
                                _passwordIsVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  child: Text(
                                    englishActive ? "Login" : "Masuk",
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              englishActive
                                  ? "Don't have an account? "
                                  : "Belum punya akun? ",
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                "/register",
                              ),
                              child: Text(
                                englishActive ? "Register" : "Daftar",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 20),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () =>
                            isEnglishNotifier.value = !isEnglishNotifier.value,
                        icon: Text(
                          englishActive ? "🇬🇧" : "🇮🇩",
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
