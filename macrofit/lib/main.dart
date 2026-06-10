import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // app ini menggunakan flutter_dotenv untuk menyimpan API key secara aman
  try {
    await dotenv.load(fileName: "key.env");
  } catch (e) {
    debugPrint("MacroFit: Error loading key.env file: $e");
  }

  try {
    await Firebase.initializeApp(
      //deteksi otomatis platform dan menggunakan konfigurasi yang sesuai
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("MacroFit: Firebase Initialization Error: $e");
  }

  //menyembunyikan status bar dan navigation bar untuk pengalaman full-screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MacroFit',
      theme: MacroFitTheme.lightTheme,
      darkTheme: MacroFitTheme.darkTheme,
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

        if (authSnapshot.hasData) {
          // 🟢 TAMBAHKAN KEY PADA FUTUREBUILDER
          // Ini memastikan setiap kali user berubah, FutureBuilder akan dibuat ulang
          return FutureBuilder<DocumentSnapshot>(
            key: ValueKey(authSnapshot.data!.uid),
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(
                  const GetOptions(source: Source.server),
                ), // Memaksa ambil dari server
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              //apabila dbsnapshot tidak memiliki data atau dokumen tidak ada, arahkan ke onboarding
              if (!dbSnapshot.hasData || !dbSnapshot.data!.exists) {
                return const OnboardingPage();
              }
              //deklarasi userData sebagai Map<String, dynamic> untuk mengambil diet_code
              final userData = dbSnapshot.data!.data() as Map<String, dynamic>;
              final dietCode = userData['diet_code'];

              if (dietCode != null && dietCode.toString().isNotEmpty) {
                return const NavigationMenu(key: ValueKey('main_nav'));
              } else {
                return const OnboardingPage();
              }
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}
