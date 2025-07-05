import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLogin = true;
  String _error = '';

  Future<void> _submit() async {
    setState(() => _error = '');
    try {
      if (_isLogin) {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error');
    } catch (e) {
      setState(() => _error = 'Error inesperado');
    }
  }

  Future<void> _submitGoogle() async {
    if (!mounted) return;
    setState(() => _error = '');
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        if (!mounted) return;
        setState(() => _error = 'Inicio cancelado.');
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'account-exists-with-different-credential') {
        msg = 'El correo ya está vinculado con otro proveedor.';
      } else {
        msg = e.message ?? 'Error Google Sign-In';
      }
      if (!mounted) return;
      setState(() => _error = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error inesperado en Google Sign‑In');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar sesión' : 'Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isLogin)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Iniciar sesión' : 'Registrarse'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Iniciar con Google'),
              onPressed: _submitGoogle,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _error = '';
                });
              },
              child: Text(_isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
