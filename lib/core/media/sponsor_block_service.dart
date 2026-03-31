import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SponsorSegment {
  final double start;
  final double end;
  final String category;

  SponsorSegment({
    required this.start,
    required this.end,
    required this.category,
  });

  factory SponsorSegment.fromJson(Map<String, dynamic> json) {
    final segment = json['segment'] as List<dynamic>;
    return SponsorSegment(
      start: (segment[0] as num).toDouble(),
      end: (segment[1] as num).toDouble(),
      category: json['category'] as String,
    );
  }
}

class SponsorBlockService {
  static Future<List<SponsorSegment>> getSegments(String videoId) async {
    try {
      final url = Uri.parse(
          'https://sponsor.ajay.app/api/skipSegments?videoID=$videoId&category=sponsor&category=intro&category=outro&category=interaction&category=selfpromo&category=music_offtopic');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => SponsorSegment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching sponsor segments: $e');
    }
    return [];
  }
}
