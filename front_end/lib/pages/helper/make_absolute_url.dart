String makeAbsolute(String backendBase, String url) {
  try {
    final u = Uri.parse(url);
    if (u.isAbsolute) return url;
  } catch (_) {}
  // _backendBase est défini dans ton state
  return '$backendBase${url.startsWith('/') ? '' : '/'}$url';
}
