import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../notes/services/notes_service.dart';
import '../../auth/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final notesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('It Takes Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tienes apuntes aún.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'Sin título'),
                subtitle: Text(data['createdAt']?.toDate().toString() ?? ''),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/noteDetail',
                    arguments: docs[i].id,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear nuevo apunte',
        child: const Icon(Icons.add),
        onPressed: () async {
          final noteId = await NotesService().createNote('Nuevo Apunte');
          Navigator.pushNamed(context, '/noteDetail', arguments: noteId);
        },
      ),
    );
  }
}
