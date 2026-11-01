import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Сервис для шеринга с картинкой
class ShareService {
  /// Скачать изображение и поделиться
  static Future<void> shareWithImage({
    required String imageUrl,
    required String text,
    required String subject,
  }) async {
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        Share.share(text, subject: subject);
        return;
      }

      final bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cocktail_share.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject,
      );
    } catch (e) {
      Share.share(text, subject: subject);
    }
  }

  static Future<void> shareText({
    required String text,
    required String subject,
  }) async {
    await Share.share(text, subject: subject);
  }
}