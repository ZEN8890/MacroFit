import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macrofit/navigation_menu.dart';
import 'package:macrofit/pages/home_page.dart'; // Pastikan import HomePage
import 'package:macrofit/pages/login_page.dart';
import 'package:macrofit/pages/onboarding_page.dart';
import 'package:macrofit/pages/register_page.dart';
import 'firebase_options.dart';
import 'Theme/Elements.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("MacroFit: Firebase Initialization Error: $e");
  }

  // 2. Sembunyikan Navigasi Bar Sistem (Samsung/Android)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MacroFit());
}

class MacroFit extends StatelessWidget {
  const MacroFit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MacroFit',
      theme: MacroFitTheme.lightTheme,
      darkTheme: MacroFitTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Menggunakan home sebagai pintu masuk utama yang cerdas
      home: const AuthWrapper(),

      routes: {
        "/register": (context) => const RegisterPage(),
        "/login": (context) => const LoginPage(),
        "/onboarding": (context) => const OnboardingPage(),
      },
    );
  }
}

// --- LOGIKA PENGECEKAN STATUS USER ---
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
                  // MODIFIKASI DISINI:
                  // User lama diarahkan ke NavigationMenu (yang berisi PageView)
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
