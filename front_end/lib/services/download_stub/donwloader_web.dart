// web implementation
import 'dart:html' as html;

Future<void> platformDownloadFile(String url, String filename) async {
  try {
    final req = await html.HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'blob',
    );
    final blob = req.response as html.Blob;
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
  } catch (e) {
    throw Exception('Échec du téléchargement Web: $e');
  }
}
