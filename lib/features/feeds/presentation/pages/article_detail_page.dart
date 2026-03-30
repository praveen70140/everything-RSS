import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/local_db.dart';
import '../../data/models/feed_entry.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailPage extends StatefulWidget {
  final FeedEntry entry;

  const ArticleDetailPage({super.key, required this.entry});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  bool _isReaderMode = false;
  bool _isLoadingReaderMode = false;
  String? _readerModeContent;
  String? _readerModeError;

  Future<void> _fetchReaderMode() async {
    if (_readerModeContent != null) {
      setState(() {
        _isReaderMode = true;
      });
      return;
    }

    setState(() {
      _isLoadingReaderMode = true;
      _readerModeError = null;
    });

    try {
      final baseUrl = localDb.mercuryParserUrl;
      final cleanBaseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final url = Uri.parse(
          '$cleanBaseUrl/parser?url=${Uri.encodeComponent(widget.entry.link)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _readerModeContent = data['content'];
          _isReaderMode = true;
        });
      } else {
        setState(() {
          _readerModeError =
              'Failed to extract content: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _readerModeError =
            'Could not connect to parser service. Make sure it is running.';
      });
    } finally {
      setState(() {
        _isLoadingReaderMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crust,
      appBar: AppBar(
        backgroundColor: AppColors.crust,
        title: Text(
          widget.entry.title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isReaderMode ? Icons.article : Icons.article_outlined,
              color: _isReaderMode ? AppColors.blue : AppColors.text,
            ),
            tooltip: 'Reader Mode',
            onPressed: () {
              if (_isReaderMode) {
                setState(() {
                  _isReaderMode = false;
                });
              } else {
                _fetchReaderMode();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in Browser',
            onPressed: () async {
              final url = Uri.parse(widget.entry.link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                // Fallback attempt to just launch anyway, handling errors
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Could not launch ${widget.entry.link}');
                }
              }
            },
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entry.title,
            style: GoogleFonts.epilogue(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.surface1),
          const SizedBox(height: 24),
          if (_isLoadingReaderMode)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            )
          else if (_readerModeError != null && _isReaderMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Reader Mode Error',
                      style: GoogleFonts.epilogue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _readerModeError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.subtext1),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isReaderMode = false;
                          _readerModeError = null;
                        });
                      },
                      child: const Text('Back to Normal View'),
                    )
                  ],
                ),
              ),
            )
          else ...[
            if (!_isReaderMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface0,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.subtext1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Showing RSS summary. Tap the article icon above to fetch the full text.',
                        style: GoogleFonts.manrope(
                          color: AppColors.subtext1,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Html(
              data: _isReaderMode
                  ? (_readerModeContent ?? '')
                  : widget.entry.subtitle,
              style: {
                "body": Style(
                  fontFamily: GoogleFonts.manrope().fontFamily,
                  fontSize: FontSize(18.0),
                  color: AppColors.text,
                  lineHeight: LineHeight(1.6),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "a": Style(
                  color: AppColors.blue,
                  textDecoration: TextDecoration.none,
                ),
                "img": Style(
                  width: Width(100, Unit.percent),
                  height: Height.auto(),
                  margin: Margins.only(top: 16.0, bottom: 16.0),
                ),
                "blockquote": Style(
                  margin: Margins.only(left: 16.0, top: 16.0, bottom: 16.0),
                  padding: HtmlPaddings.only(left: 16.0),
                  border: Border(
                      left: BorderSide(color: AppColors.surface1, width: 4.0)),
                  fontStyle: FontStyle.italic,
                  color: AppColors.subtext1,
                ),
                "h1": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(28.0),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24.0, bottom: 12.0),
                ),
                "h2": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(24.0),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24.0, bottom: 12.0),
                ),
                "h3": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(20.0),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 20.0, bottom: 10.0),
                ),
              },
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
