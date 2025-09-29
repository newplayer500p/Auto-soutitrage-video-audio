import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:front_end/services/download_serive.dart';

/// Affiche une boîte de dialogue listant les fichiers disponibles et permet
/// de les télécharger / ouvrir avec la classe Downloader.
void showDownloadOptions(BuildContext context, Map<String, String> urls) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Résultat - Téléchargements'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: urls.entries.where((e) => e.value.trim().isNotEmpty).map((
            entry,
          ) {
            final key = entry.key;
            final url = entry.value.trim();
            final filename = _fileNameFromUrl(url, fallback: '$key.bin');
            final label = _labelFromKey(key);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                title: Text(label),
                subtitle: Text(filename),
                trailing: ElevatedButton(
                  onPressed: url.isEmpty
                      ? null
                      : () async {
                          Navigator.of(context).pop(); // fermer la dialog
                          final downloader = Downloader();
                          try {
                            await downloader.downloadFile(url, filename);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('\$label téléchargé')),
                            );
                          } catch (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur téléchargement: \$err'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(kIsWeb ? 'Télécharger' : 'Ouvrir/Télécharger'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

String _fileNameFromUrl(String url, {required String fallback}) {
  try {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return fallback;
  } catch (_) {
    return fallback;
  }
}

String _labelFromKey(String key) {
  switch (key) {
    case 'video':
      return 'Vidéo originale';
    case 'vocals':
      return 'Audio (vocals)';
    case 'srt':
      return 'Fichier SRT';
    case 'subtitled':
      return 'Vidéo sous-titrée';
    default:
      return key;
  }
}
