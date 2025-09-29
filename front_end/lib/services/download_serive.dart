import './open_file/downloader_io.dart'
    if (dart.library.html) './open_file/downloader_web.dart';

/// Télécharge et ouvre (ou déclenche le téléchargement) d'un fichier.
class Downloader {
  /// Delegate to platform-specific implementation.
  Future<void> downloadFile(String url, String filename) =>
      platformDownloadFile(url, filename);
}
