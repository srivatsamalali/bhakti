// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

String createBlobUrl(Uint8List bytes, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

Future<String> saveLocalMedia(String id, Uint8List bytes, String extension, String mimeType) async {
  return createBlobUrl(bytes, mimeType);
}
