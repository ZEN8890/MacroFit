import 'package:flutter/material.dart';
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
  bool _isPasswordVisible = false;

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
    setState(() => _isLoading = false);

    if (result == "success") {
      Notify.success(
        context,
        isEnglish ? "Login successful!" : "Login berhasil!",
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    } else {
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
          resizeToAvoidBottomInset:
              false, // Mencegah UI terangkat oleh keyboard
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
                        // 🟢 PASSWORD FIELD DENGAN OBSCURE TOGGLE
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                              icon: Icon(
                                _isPasswordVisible
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
                // Tombol Bahasa
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
                          englishActive ? "🇮🇩" : "🇬🇧",
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
