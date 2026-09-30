import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// -----------------------------------------------------------------------
// Firebase account this app is wired to: nexusarbaz2023@gmail.com
// Run `flutterfire configure` (see README.md) once, logged into that
// Google account, and it will generate the real lib/firebase_options.dart
// for you — replacing the placeholder file included in this project.
// Every platform (Windows, Mac, Web, Android) you build from this same
// codebase will then read/write the exact same Firestore data.
// -----------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AsphaltTicketApp());
}

class AsphaltTicketApp extends StatelessWidget {
  const AsphaltTicketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Asphalt One — Ticketing',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootGate(),
      ),
    );
  }
}

/// Shows the login screen until someone is signed in, then the home screen.
/// Firestore security rules (see firestore.rules) require authentication,
/// so every device someone uses must sign in with a company-issued account.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
