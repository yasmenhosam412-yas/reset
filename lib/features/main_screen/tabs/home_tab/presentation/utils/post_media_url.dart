/// True when [url] likely points to a video we uploaded or a standard video extension.
bool postMediaUrlLooksLikeVideo(String url) {
  final base = url.toLowerCase().trim().split('?').first;
  const exts = ['.mp4', '.webm', '.mov', '.m4v', '.mkv'];
  for (final e in exts) {
    if (base.endsWith(e)) return true;
    if (base.contains('$e?')) return true;
  }
  return false;
}
