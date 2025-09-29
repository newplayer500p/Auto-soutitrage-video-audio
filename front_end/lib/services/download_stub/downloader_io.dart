// Implementation for non-web platforms (Linux / macOS / Windows / mobile)
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

Future<void> platformDownloadFile(String url, String filename) async {
  final dio = Dio();

  // Try to save in Users' Downloads folder if available, otherwise fallback to current dir.
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';
  final downloadsDir = Directory(p.join(home, 'Downloads'));
  if (!await downloadsDir.exists()) {
    try {
      await downloadsDir.create(recursive: true);
    } catch (_) {
      // fallback: use current directory
    }
  }

  final savePath = p.join(
    downloadsDir.existsSync() ? downloadsDir.path : '.',
    filename,
  );

  try {
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final file = File(savePath);
    await file.writeAsBytes(response.data ?? [], flush: true);

    // Try to open the file (best-effort). Commands differ by OS.
    try {
      if (Platform.isLinux) {
        await Process.start('xdg-open', [file.path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [file.path]);
      } else if (Platform.isWindows) {
        // 'start' is a shell builtin, spawn via cmd
        await Process.start('cmd', ['/C', 'start', '', file.path]);
      }
    } catch (_) {
      // ignore opening errors — file is still saved
    }
  } catch (e) {
    throw Exception('Échec du téléchargement (IO): \$e');
  }
}
