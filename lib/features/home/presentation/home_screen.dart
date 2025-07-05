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
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final controller = TextEditingController(
                        text: data['title'],
                      );
                      String? editedTitle = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Editar título'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Nuevo título',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isNotEmpty) {
                                  Navigator.pop(context, text);
                                }
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      );
                      if (editedTitle != null && editedTitle.isNotEmpty) {
                        await NotesService().updateNoteTitle(
                          docs[i].id,
                          editedTitle,
                        );
                      }
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar apunte'),
                          content: const Text(
                            '¿Estás seguro de que deseas eliminar este apunte?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await NotesService().deleteNote(docs[i].id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear nuevo apunte',
        child: const Icon(Icons.add),
        onPressed: () async {
          String? newTitle = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Nuevo Apunte'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Título del apunte',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Cancelar
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(context, text);
                      } else {
                        Navigator.pop(context, 'Nuevo apunte');
                      }
                    },
                    child: const Text('Crear'),
                  ),
                ],
              );
            },
          );
          if (newTitle != null && newTitle.isNotEmpty) {
            final noteId = await NotesService().createNote(newTitle);
            Navigator.pushNamed(context, '/noteDetail', arguments: noteId);
          }
        },
      ),
    );
  }
}
