import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

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

  DateTime? _selectedDateOfBirth;
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

  Future<void> _selectDateOfBirth(BuildContext context, bool isEnglish) async {
    final DateTime now = DateTime.now();
    final DateTime initialCalDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? initialCalDate,
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).primaryColor,
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void handleRegister() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String username = _usernameController.text
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('@', '');
    final bool isEnglish = isEnglishNotifier.value;

    if (email.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        username.isEmpty ||
        _selectedDateOfBirth == null) {
      Notify.error(
        context,
        isEnglish
            ? "Fields cannot be empty. Please select your birthdate."
            : "Form tidak boleh kosong. Silakan pilih tanggal lahir Anda.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          Notify.error(
            context,
            isEnglish
                ? "Username already taken! Try another one."
                : "Username sudah terdaftar! Gunakan yang lain.",
          );
        }
        return;
      }

      String? result = await _authService.userRegistration(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        username: username,
        dateOfBirth: _selectedDateOfBirth!,
      );

      if (result == "success") {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Notify.success(
            context,
            isEnglish
                ? "Registration successful! Please login to continue."
                : "Registrasi berhasil! Silakan login untuk melanjutkan.",
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/login");
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          Notify.error(
            context,
            result == "Registrasi gagal" && isEnglish
                ? "Registration failed"
                : (result ?? "Registrasi gagal"),
          );
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
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        String birthdateText = englishActive
            ? "Select Date of Birth"
            : "Pilih Tanggal Lahir";
        if (_selectedDateOfBirth != null) {
          birthdateText =
              "${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}";
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(englishActive ? "Registration" : "Pendaftaran"),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: englishActive ? "First name" : "Nama depan",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: englishActive
                          ? "Last name (Optional)"
                          : "Nama belakang (Opsional)",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => _selectDateOfBirth(context, englishActive),
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // 👈 Menjaga efek ripple klik tetap rounded
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white30
                              : Colors
                                    .grey
                                    .shade400, // Menyesuaikan warna border abu form standar
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            birthdateText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _selectedDateOfBirth != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedDateOfBirth != null
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: englishActive ? "Username" : "Nama pengguna",
                      prefixText: "@ ",
                      prefixStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      border: const OutlineInputBorder(),
                      helperText: englishActive
                          ? "Username spaces are not allowed and must be unique."
                          : "Username tidak boleh memakai spasi dan wajib unik.",
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
                            child: Text(englishActive ? "Register" : "Daftar"),
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        englishActive
                            ? "Already have an account? "
                            : "Sudah memiliki akun? ",
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, "/login"),
                        child: Text(englishActive ? "Login" : "Masuk"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
