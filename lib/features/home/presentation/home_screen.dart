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
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23242B),
        elevation: 0,
        title: const Text(
          'It Takes Notes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.white24),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No tienes apuntes aún.',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF23242B),
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    data['title'] ?? 'Sin título',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    data['createdAt']?.toDate().toString() ?? '',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/noteDetail',
                      arguments: docs[i].id,
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF23242B),
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final controller = TextEditingController(
                          text: data['title'],
                        );
                        String? editedTitle = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF23242B),
                            title: const Text(
                              'Editar título',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Nuevo título',
                                labelStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white,
                                ),
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
                            backgroundColor: const Color(0xFF23242B),
                            title: const Text(
                              'Eliminar apunte',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              '¿Estás seguro de que deseas eliminar este apunte?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Editar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.white,
        tooltip: 'Crear nuevo apunte',
        child: const Icon(Icons.add),
        onPressed: () async {
          String? newTitle = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                backgroundColor: const Color(0xFF23242B),
                title: const Text(
                  'Nuevo Apunte',
                  style: TextStyle(color: Colors.white),
                ),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Título del apunte',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                    ),
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
