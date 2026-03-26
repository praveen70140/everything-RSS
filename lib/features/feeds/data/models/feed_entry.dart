enum MediaType { image, video, audio, text }

class FeedEntry {
  final String id;
  final String title;
  final String subtitle;
  final String link;
  final MediaType mediaType;
  final String? mediaUrl;

  FeedEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.link,
    required this.mediaType,
    this.mediaUrl,
  });
}
