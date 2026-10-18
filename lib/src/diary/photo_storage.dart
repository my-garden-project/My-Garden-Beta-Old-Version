import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class DiaryPhotoStorage {
  DiaryPhotoStorage({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pick(ImageSource source) => _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );

  Future<String> persist(XFile source, String entryId) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/garden_mii/diary');
    await directory.create(recursive: true);
    final extension = _safeExtension(source.path);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final destination = File('${directory.path}/${entryId}_$stamp$extension');
    await File(source.path).copy(destination.path);
    return destination.path;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String _safeExtension(String path) {
    final fileName = path.split('/').last;
    final dot = fileName.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final extension = fileName.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.heic', '.webp'}.contains(extension)
        ? extension
        : '.jpg';
  }
}
