import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../../env.dart';
import 'package:reorderables/reorderables.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  late final OpenAIClient _client;
  NotesService() {
    _client = OpenAIClient(apiKey: Env.openAiKey);
    _client.apiKey = Env.openAiKey;
  }

  Future<void> createUserIfNotExists(String email, String displayName) async {
    final userDoc = _firestore.collection('users').doc(_userId);
    if (!(await userDoc.get()).exists) {
      await userDoc.set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> createNote(String title) async {
    final docRef = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .add({
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
          'rawText': '',
          'organizedText': '',
          'aiProcessed': false,
        });
    return docRef.id;
  }

  Future<String> uploadImage(String noteId, XFile img) async {
    final file = File(img.path);
    final path =
        'user_uploads/$_userId/$noteId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> addImageToNote({
    required String noteId,
    required String imageUrl,
    required int order,
    String ocrText = '',
  }) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .doc(noteId)
        .collection('images')
        .add({'imageUrl': imageUrl, 'order': order});
  }

  Future<void> updateRawText(String noteId, String rawText) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .doc(noteId)
        .update({'rawText': rawText});
  }

  Future<void> updateOrganizedText(String noteId, String organizedText) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .doc(noteId)
        .update({'organizedText': organizedText, 'aiProcessed': true});
  }

  Future<Map<String, dynamic>> getNote(String noteId) async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .doc(noteId)
        .get();
    return doc.data()!;
  }

  Future<String> processWithAi(String noteId, String rawText) async {
    try {
      final request = CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-4o-mini'),
        messages: [
          ChatCompletionMessage.system(
            content: '''
            Eres un asistente que organiza notas escolares. 
            Debes:
            1. Identificar conceptos clave
            2. Estructurar en apartados con títulos
            3. Usar formato markdown
            4. Mantener un tono académico
            ''',
          ),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(rawText),
          ),
        ],
        temperature: 0.2,
        maxTokens: 2000,
      );

      final response = await _client.createChatCompletion(request: request);

      final organizedText = response.choices.first.message.content ?? '';

      await updateOrganizedText(noteId, organizedText);

      return organizedText;
    } catch (e) {
      print('Error en processWithAi: $e');
      throw Exception('Error al procesar con IA: $e');
    }
  }

  Future<void> updateNoteTitle(String noteId, String newTitle) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .update({'title': newTitle});
  }

  Future<void> deleteNote(String noteId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}
