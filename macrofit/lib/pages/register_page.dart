import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../utils/notification_helper.dart'; // 🟢 Import helper notifikasi

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void handleRegister() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String usernameHandle = _usernameController.text
        .trim()
        .toLowerCase()
        .replaceAll(' ', '');

    if (email.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        usernameHandle.isEmpty) {
      // 🟢 GANTI: ScaffoldMessenger ke Notify.error
      Notify.error(context, "Form tidak boleh ada yang kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🟢 LOGIKA VALIDASI: Cek keunikan username
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username_handle', isEqualTo: usernameHandle)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          // 🟢 GANTI: ScaffoldMessenger ke Notify.error
          Notify.error(context, "Username sudah terdaftar! Gunakan yang lain.");
        }
        return;
      }

      String? result = await _authService.userRegistration(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        usernameHandle: usernameHandle,
      );

      if (result == "success") {
        // 🟢 GANTI: ScaffoldMessenger ke Notify.success
        if (mounted) Notify.success(context, "Registrasi berhasil!");

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/login");
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          // 🟢 GANTI: ScaffoldMessenger ke Notify.error
          Notify.error(context, result ?? "Registrasi gagal");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Notify.error(context, "Error: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registration")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "First name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Last name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixText: "@ ",
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(),
                  helperText:
                      "Username tidak boleh memakai spasi dan wajib unik.",
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
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
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: handleRegister,
                        child: const Text("Register"),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, "/login"),
                    child: const Text("Login"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
