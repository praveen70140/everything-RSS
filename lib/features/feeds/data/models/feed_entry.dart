enum MediaType { image, video, audio, text }

class FeedEntry {
  final String id;
  final String title;
  final String subtitle;
  final String link;
  final MediaType mediaType;
  final String? mediaUrl;
  final String? author;
  final DateTime? pubDate;
  String? feedName; // Added to identify feed source in Unified view
  String? feedUrl; // Added for saving to DB from Unified view

  FeedEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.link,
    required this.mediaType,
    this.mediaUrl,
    this.author,
    this.pubDate,
    this.feedName,
    this.feedUrl,
  });
}
