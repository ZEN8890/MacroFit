import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 TAMBAHKAN IMPORT INI UNTUK MENGECEK KEUNIKAN USERNAME
import '../services/auth_services.dart';

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
  // 🟢 1. INARKAN CONTROLLER BARU UNTUK USERNAME HANDLE
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose(); // 🟢 DISPOSE CONTROLLER USERNAME
    super.dispose();
  }

  void handleRegister() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    // 🟢 Ambil input username, paksa jadi huruf kecil dan buang spasi kosong ala Instagram
    final String usernameHandle = _usernameController.text
        .trim()
        .toLowerCase()
        .replaceAll(' ', '');

    if (email.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        usernameHandle.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Form cannot be empty")));
      return;
    }

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 🟢 2. LOGIKA VALIDASI UTAMA: Cek keunikan username ke Cloud Firestore database
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username_handle', isEqualTo: usernameHandle)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        // Jika list dokumen tidak kosong, berarti username ini sudah hangus diambil orang lain
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                "⚠️ Username sudah terdaftar! Silakan gunakan username handle lain.",
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return; // Hentikan fungsi pendaftaran di sini!
      }

      // 🟢 3. OPER PARAMETER USERNAME BARU KE AUTH SERVICE KAMU
      String? result = await _authService.userRegistration(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        usernameHandle: usernameHandle, // 🟢 SUNTIKKAN VARIABEL HANDLE DI SINI
      );

      if (result == "success") {
        messenger.showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );

        await Future.delayed(const Duration(milliseconds: 150));
        navigator.pushReplacementNamed("/login");
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            SnackBar(content: Text(result ?? "Registration failed")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
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

              // 🟢 4. UI SEKSI INPUT USERNAME BARU (GAYA INSTAGRAM HANDLE)
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: "Username (e.g: stvnnvts8)",
                  prefixText:
                      "@ ", // Menampilkan simbol @ di depan field input teks
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
