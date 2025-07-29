import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../notes/services/notes_service.dart';
import '../../auth/services/auth_service.dart';
import 'package:blur/blur.dart';

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
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final noteId = docs[i].id;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('notes')
                    .doc(noteId)
                    .collection('images')
                    .orderBy('order')
                    .limit(1)
                    .get(),
                builder: (context, imgSnapshot) {
                  String? imageUrl;
                  if (imgSnapshot.hasData &&
                      imgSnapshot.data!.docs.isNotEmpty) {
                    imageUrl =
                        imgSnapshot.data!.docs.first['imageUrl'] as String?;
                  }

                  Widget cardContent = Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        data['title'] ?? 'Sin título',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    cardContent = Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child:
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: Colors.black26),
                              ).blurred(
                                blur: 2,
                                colorOpacity: 0.2,
                                borderRadius: BorderRadius.circular(16),
                                overlay: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              data['title'] ?? 'Sin título',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/noteDetail',
                        arguments: noteId,
                      );
                    },
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: cardContent,
                    ),
                  );
                },
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
