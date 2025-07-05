import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../notes/services/notes_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Login con correo y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  //Registro con correo y contraseña
  Future<User?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);
    await NotesService().createUserIfNotExists(email, displayName);
    return credential.user;
  }

  //Google sign-in Web and Android
  Future<User?> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();

    try {
      UserCredential credential;
      if (kIsWeb) {
        // Flujo Web
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Flujo Android/iOS
        credential = await _auth.signInWithProvider(googleProvider);
      }

      final user = credential.user;
      if (user != null) {
        await NotesService().createUserIfNotExists(
          user.email ?? '',
          user.displayName ?? '',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'auth/popup-closed-by-user') {
        // Usuario cerró el popup
        print("El usuario cerro el pop up");
        return null;
      } else {
        // Otro error
        print("Error desconocido aun");
        return null;
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
