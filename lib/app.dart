// app.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/note_detail/presentation/note_detail_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITTAKESNOTES',
      initialRoute: '/',
      routes: {
        '/': (ctx) => const AuthGate(),
        '/noteDetail': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as String;
          return NoteDetailScreen(noteId: args);
        },
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
