import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../notes/services/notes_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NotesService _notesService = NotesService();
  final ImagePicker _picker = ImagePicker();
  List<String> _images = [];
  String _rawText = '';
  String _organizedText = '';
  bool _processingOcr = false, _processingAi = false;
  String _noteTitle = "";

  Future _pickImages() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecciona origen'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Galería'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Cámara'),
          ),
        ],
      ),
    );

    if (source == null) return;

    if (source == ImageSource.gallery) {
      final pictures = await _picker.pickMultiImage();
      if (pictures != null) {
        for (var pic in pictures) {
          final url = await _notesService.uploadImage(widget.noteId, pic);
          await _notesService.addImageToNote(
            noteId: widget.noteId,
            imageUrl: url,
            order: _images.length + 1,
          );
          setState(() => _images.add(url));
        }
      }
    } else if (source == ImageSource.camera) {
      final pic = await _picker.pickImage(source: ImageSource.camera);
      if (pic != null) {
        final url = await _notesService.uploadImage(widget.noteId, pic);
        await _notesService.addImageToNote(
          noteId: widget.noteId,
          imageUrl: url,
          order: _images.length + 1,
        );
        setState(() => _images.add(url));
      }
    }
  }

  Future _runOcr() async {
    setState(() => _processingOcr = true);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String allText = '';

    for (var url in _images) {
      // Descargar la imagen a un archivo temporal
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(response.bodyBytes);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final result = await textRecognizer.processImage(inputImage);
      allText += result.text + '\n';

      // Elimina el archivo temporal si lo deseas
      await tempFile.delete();
    }

    textRecognizer.close();
    await _notesService.updateRawText(widget.noteId, allText);
    setState(() {
      _rawText = allText;
      _processingOcr = false;
    });
  }

  Future _runAi() async {
    setState(() => _processingAi = true);
    final organized = await _notesService.processWithAi(
      widget.noteId,
      _rawText,
    );
    await _notesService.updateOrganizedText(widget.noteId, organized);
    setState(() {
      _organizedText = organized;
      _processingAi = false;
    });
  }

  Future<String> uploadImage(String noteId, XFile image) async {
    final storageRef = FirebaseStorage.instance.ref().child(
      'notes/$noteId/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
    );
    final uploadTask = await storageRef.putFile(File(image.path));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> addImageToNote({
    required String noteId,
    required String imageUrl,
    required int order,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .collection('images')
        .add({
          'url': imageUrl,
          'order': order,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future _loadNote() async {
    final note = await _notesService.getNote(widget.noteId);
    final images = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('notes')
        .doc(widget.noteId)
        .collection('images')
        .orderBy('order')
        .get();

    setState(() {
      _noteTitle = note['title'] ?? '';
      _rawText = note['rawText'] ?? '';
      _organizedText = note['organizedText'] ?? '';
      _images = images.docs
          .where((doc) => doc.data().containsKey('imageUrl'))
          .map((doc) => doc['imageUrl'] as String)
          .toList();
    });
  }

  Future<void> _deleteImage(int index) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final imagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(widget.noteId)
        .collection('images');

    // Buscar el documento Firestore por imageUrl
    final snapshot = await imagesRef
        .where('imageUrl', isEqualTo: _images[index])
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      // Eliminar de Storage
      final url = doc['imageUrl'];
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (_) {}
      // Eliminar de Firestore
      await doc.reference.delete();
    }

    setState(() {
      _images.removeAt(index);
    });

    // Reordenar los campos order en Firestore
    for (int i = 0; i < _images.length; i++) {
      final snap = await imagesRef
          .where('imageUrl', isEqualTo: _images[i])
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'order': i + 1});
      }
    }
  }

  Future<void> _moveImage(int oldIndex, int newIndex) async {
    if (newIndex < 0 || newIndex >= _images.length) return;

    setState(() {
      final img = _images.removeAt(oldIndex);
      _images.insert(newIndex, img);
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final imagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(widget.noteId)
        .collection('images');

    // Actualizar el campo order en Firestore
    for (int i = 0; i < _images.length; i++) {
      final snap = await imagesRef
          .where('imageUrl', isEqualTo: _images[i])
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'order': i + 1});
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23242B),
        elevation: 0,
        title: Text(
          _noteTitle.isNotEmpty ? _noteTitle : 'Detalle de Apunte',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableWrap(
              spacing: 12,
              runSpacing: 12,
              maxMainAxisCount: 2,
              onReorder: (oldIndex, newIndex) async {
                await _moveImage(oldIndex, newIndex);
              },
              children: _images.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Stack(
                  key: ValueKey(url),
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Número de orden en la esquina superior izquierda
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        onPressed: () => _deleteImage(idx),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Agregar imágenes'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _processingOcr ? null : _runOcr,
              child: Text(
                _processingOcr ? 'Procesando OCR...' : 'Extraer texto (OCR)',
              ),
            ),
            if (_rawText.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Texto crudo:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF23242B),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  controller: TextEditingController(text: _rawText),
                  onChanged: (v) => _rawText = v,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: !_rawText.isNotEmpty || _processingAi ? null : _runAi,
              child: Text(
                _processingAi ? 'IA procesando...' : 'Organizar con IA',
              ),
            ),
            if (_organizedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Texto organizado:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF23242B),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  controller: TextEditingController(text: _organizedText),
                  onChanged: (v) => _organizedText = v,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
