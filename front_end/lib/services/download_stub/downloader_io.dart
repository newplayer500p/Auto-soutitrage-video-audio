import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

Future<void> platformDownloadFile(String url, String filename) async {
  final dio = Dio();

  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';
  final downloadsDir = Directory(p.join(home, 'Downloads'));
  if (!await downloadsDir.exists()) {
    try {
      await downloadsDir.create(recursive: true);
    } catch (_) {}
  }
  final savePath = p.join(
    downloadsDir.existsSync() ? downloadsDir.path : '.',
    filename,
  );

  try {
    final response = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (response.statusCode == null || response.statusCode! >= 400) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final bytes = response.data ?? <int>[];
    final file = File(savePath);
    await file.writeAsBytes(bytes, flush: true);

    // best-effort open the file
    try {
      if (Platform.isLinux) {
        await Process.start('xdg-open', [file.path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.start('cmd', ['/C', 'start', '', file.path]);
      }
    } catch (_) {}
  } catch (e, st) {
    throw Exception('Échec du téléchargement (IO): $e \n $st');
  }
}
