import 'dart:convert';

Map<String, dynamic>? infoAsMap(dynamic info) {
  if (info == null) return null;
  if (info is Map<String, dynamic>) return info;
  if (info is String) {
    // Essaie de parser du JSON si possible
    try {
      final parsed = jsonDecode(info);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      // ignore parse error
    }
    // pas JSON => retourne un map simple contenant la string sous 'data'
    return {'data': info};
  }
  // Pour tout autre type, on retourne sa string representation
  return {'data': info.toString()};
}
