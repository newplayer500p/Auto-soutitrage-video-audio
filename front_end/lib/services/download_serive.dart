// Choisit l'implémentation en fonction de la plateforme.
import './download_stub/downloader_io.dart'
    if (dart.library.html) './download_stub/donwloader_web.dart';

/// Télécharge et ouvre (ou déclenche le téléchargement) d'un fichier.
class Downloader {
  /// Delegate to platform-specific implementation.
  Future<void> downloadFile(String url, String filename) =>
      platformDownloadFile(url, filename);
}
