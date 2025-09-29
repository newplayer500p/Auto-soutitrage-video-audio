// Web implementation: utilise un <a> pour forcer le téléchargement / ouvrir dans un nouvel onglet.
import 'dart:html' as html;

Future<void> platformDownloadFile(String url, String filename) async {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..target = '_blank';

    // some browsers require the anchor to be in the document
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    throw Exception('Échec du téléchargement Web: \$e');
  }
}
