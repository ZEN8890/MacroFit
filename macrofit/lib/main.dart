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

  try {
    await dotenv.load(fileName: "key.env");
  } catch (e) {
    debugPrint("MacroFit: Error loading key.env file: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("MacroFit: Firebase Initialization Error: $e");
  }

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

        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            key: ValueKey(authSnapshot.data!.uid),
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(const GetOptions(source: Source.server)),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!dbSnapshot.hasData || !dbSnapshot.data!.exists) {
                return const OnboardingPage();
              }

              final userData = dbSnapshot.data!.data() as Map<String, dynamic>?;
              bool hasCompletedOnboarding =
                  userData?['has_completed_onboarding'] ?? false;

              if (hasCompletedOnboarding) {
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
