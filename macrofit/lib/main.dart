import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:macrofit/navigation_menu.dart';
import 'package:macrofit/pages/login_page.dart';
import 'package:macrofit/pages/onboarding_page.dart';
import 'package:macrofit/pages/register_page.dart';
import 'firebase_options.dart';
import 'Theme/Elements.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat konfigurasi dari file key.env
  try {
    await dotenv.load(fileName: "key.env");
  } catch (e) {
    debugPrint("MacroFit: Error loading key.env file: $e");
  }

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("MacroFit: Firebase Initialization Error: $e");
  }

  // Sembunyikan Navigasi Bar Sistem
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Bungkus aplikasi utama dengan ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MacroFit(),
    ),
  );
}

class MacroFit extends StatelessWidget {
  const MacroFit({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil State ThemeProvider secara real-time
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MacroFit',

      // Menggunakan skema warna elegan dari berkas Theme/Elements.dart
      theme: MacroFitTheme.lightTheme,
      darkTheme: MacroFitTheme.darkTheme,

      // 🔥 PERBAIKAN: Menerjemahkan boolean isDarkMode menjadi objek ThemeMode bawaan Flutter
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: const AuthWrapper(),

      routes: {
        "/register": (context) => const RegisterPage(),
        "/login": (context) => const LoginPage(),
        "/onboarding": (context) => const OnboardingPage(),
      },
    );
  }
}

// --- LOGIKA PENGECEKAN STATUS USER (Tetap Aman & Sesuai) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                var userData = dbSnapshot.data!.data() as Map<String, dynamic>;

                if (userData.containsKey('diet_code')) {
                  return const NavigationMenu();
                }
              }

              return const OnboardingPage();
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}
