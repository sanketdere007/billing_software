import 'dart:io';

/// Downloads required Unicode TrueType fonts directly from the Google Fonts CDN
/// and saves them into the `assets/fonts/` directory for offline use.
///
/// Usage:
/// ```
/// dart run tool/setup_fonts.dart
/// ```
const Map<String, String> requiredFonts = {
  'NotoSans-Regular.ttf':
      'https://fonts.gstatic.com/s/notosans/v36/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99d41P6zHtY.ttf',
  'NotoSans-Bold.ttf':
      'https://fonts.gstatic.com/s/notosans/v36/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyAaBN9d41P6zHtY.ttf',
  'NotoSansDevanagari-Regular.ttf':
      'https://fonts.gstatic.com/s/notosansdevanagari/v26/TuGoUUFzXI5FBtUq5a8bjKYTZjtRU6Sgv3NaV_SNmI0b8QQCQmHn6B2OHjbL_08AlXQly-AzoFoW4Ow.ttf',
  'NotoSansDevanagari-Bold.ttf':
      'https://fonts.gstatic.com/s/notosansdevanagari/v26/TuGoUUFzXI5FBtUq5a8bjKYTZjtRU6Sgv3NaV_SNmI0b8QQCQmHn6B2OHjbL_08AlZMiy-AzoFoW4Ow.ttf',
};

Future<void> main() async {
  final targetDir = Directory('assets/fonts');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  print('======================================================');
  print('Setting up Unicode Fonts in ${targetDir.path}');
  print('======================================================');

  final client = HttpClient();
  var successCount = 0;

  try {
    for (final entry in requiredFonts.entries) {
      final fileName = entry.key;
      final url = entry.value;
      final file = File('${targetDir.path}/$fileName');

      if (await file.exists() && await file.length() > 0) {
        print('[EXISTS] $fileName (${await file.length()} bytes)');
        successCount++;
        continue;
      }

      print('[DOWNLOADING] $fileName...');
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();

        if (response.statusCode == 200) {
          final sink = file.openWrite();
          await response.pipe(sink);
          print('[SAVED] $fileName (${await file.length()} bytes)');
          successCount++;
        } else {
          print('[FAILED] $fileName: HTTP Status ${response.statusCode}');
        }
      } catch (e) {
        print('[ERROR] Downloading $fileName: $e');
      }
    }
  } finally {
    client.close();
  }

  print('======================================================');
  print('Setup complete: $successCount of ${requiredFonts.length} fonts ready.');
  print('======================================================');
}
