import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../notes/services/notes_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NotesService _notesService = NotesService();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  String _rawText = '';
  String _organizedText = '';
  bool _processingOcr = false, _processingAi = false;

  Future _pickImages() async {
    final pictures = await _picker.pickMultiImage();
    if (pictures != null) {
      for (var pic in pictures) {
        final url = await _notesService.uploadImage(widget.noteId, pic);
        await _notesService.addImageToNote(
          noteId: widget.noteId,
          imageUrl: url,
          order: _images.length + 1,
        );
      }
      setState(() => _images.addAll(pictures));
    }
  }

  Future _runOcr() async {
    setState(() => _processingOcr = true);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String allText = '';
    for (var img in _images) {
      final inputImage = InputImage.fromFilePath(img.path);
      final result = await textRecognizer.processImage(inputImage);
      allText += result.text + '\n';
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

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future _loadNote() async {
    final note = await _notesService.getNote(widget.noteId);
    setState(() {
      _rawText = note['rawText'] ?? '';
      _organizedText = note['organizedText'] ?? '';
      // Images también se deberían cargar
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Apunte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: _images
                  .map(
                    (img) =>
                        Image.file(File(img.path), width: 100, height: 100),
                  )
                  .toList(),
            ),
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Agregar imágenes'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _processingOcr ? null : _runOcr,
              child: Text(_processingOcr ? 'Procesando OCR...' : 'Run OCR'),
            ),
            if (_rawText.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextField(
                maxLines: null,
                decoration: const InputDecoration(labelText: 'Texto crudo'),
                controller: TextEditingController(text: _rawText),
                onChanged: (v) => _rawText = v,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: !_rawText.isNotEmpty || _processingAi ? null : _runAi,
              child: Text(
                _processingAi ? 'IA procesando...' : 'Procesar con IA',
              ),
            ),
            if (_organizedText.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextField(
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Texto organizado',
                ),
                controller: TextEditingController(text: _organizedText),
                onChanged: (v) => _organizedText = v,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
