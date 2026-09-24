import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> saveLocalMedia(String id, Uint8List bytes, String extension, String mimeType) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final sanitizedId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${appDir.path}/media_$sanitizedId.$extension');
    await file.writeAsBytes(bytes);
    return file.uri.toString();
  } catch (_) {
    return '';
  }
}

String createBlobUrl(Uint8List bytes, String mimeType) {
  return '';
}
