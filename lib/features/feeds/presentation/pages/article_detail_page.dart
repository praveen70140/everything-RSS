import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/local_db.dart';
import '../../data/models/feed_entry.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailPage extends StatefulWidget {
  final List<FeedEntry> entries;
  final int initialIndex;

  const ArticleDetailPage({
    super.key,
    required this.entries,
    required this.initialIndex,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isReaderMode = false;
  bool _isLoadingReaderMode = false;
  String? _readerModeContent;
  String? _readerModeError;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  FeedEntry get currentEntry => widget.entries[_currentIndex];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isReaderMode = false;
      _isLoadingReaderMode = false;
      _readerModeContent = null;
      _readerModeError = null;
    });
  }

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
          '$cleanBaseUrl/parser?url=${Uri.encodeComponent(currentEntry.link)}');
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

  void _handleDefine() async {
    if (_selectedText == null || _selectedText!.isEmpty) return;
    final url = Uri.parse(
        'https://www.google.com/search?q=define+${Uri.encodeComponent(_selectedText!)}');
    try {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      debugPrint('Could not launch $url');
    }
  }

  void _handleTranslate() async {
    if (_selectedText == null || _selectedText!.isEmpty) return;
    final url = Uri.parse(
        'https://translate.google.com/?sl=auto&tl=en&text=${Uri.encodeComponent(_selectedText!)}&op=translate');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url');
    }
  }

  void _showTypographyBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.crust,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double currentSize = localDb.readerFontSize;
            final String currentFont = localDb.readerFontFamily;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Typography & Accessibility',
                    style: GoogleFonts.epilogue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Font Size',
                        style: TextStyle(color: AppColors.subtext1),
                      ),
                      Text(
                        currentSize.toInt().toString(),
                        style: TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentSize,
                    min: 14.0,
                    max: 32.0,
                    divisions: 18,
                    activeColor: AppColors.blue,
                    inactiveColor: AppColors.surface1,
                    onChanged: (double value) {
                      localDb.setReaderFontSize(value);
                      setModalState(() {});
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Font Family',
                    style: TextStyle(color: AppColors.subtext1),
                  ),
                  SizedBox(height: 8),
                  DropdownButton<String>(
                    value: currentFont,
                    isExpanded: true,
                    dropdownColor: AppColors.surface0,
                    style: TextStyle(color: AppColors.text),
                    underline: Container(
                      height: 1,
                      color: AppColors.surface1,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'sans-serif',
                          child: Text('Sans-Serif (Manrope)')),
                      DropdownMenuItem(
                          value: 'serif', child: Text('Serif (Lora)')),
                      DropdownMenuItem(
                          value: 'monospace',
                          child: Text('Monospace (Fira Code)')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        localDb.setReaderFontFamily(newValue);
                        setModalState(() {});
                        setState(() {});
                      }
                    },
                  ),
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crust,
      appBar: AppBar(
        backgroundColor: AppColors.crust,
        title: Text(
          currentEntry.author ?? 'Article',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.text_fields),
            tooltip: 'Typography Settings',
            onPressed: _showTypographyBottomSheet,
          ),
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
            icon: Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              Share.share('${currentEntry.title}\n${currentEntry.link}');
            },
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: 'Open in Browser',
            onPressed: () async {
              final url = Uri.parse(currentEntry.link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Could not launch ${currentEntry.link}');
                }
              }
            },
          )
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.entries.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          return SelectionArea(
            onSelectionChanged: (SelectedContent? content) {
              _selectedText = content?.plainText;
            },
            contextMenuBuilder: (context, selectableRegionState) {
              final List<ContextMenuButtonItem> buttonItems = [
                ...selectableRegionState.contextMenuButtonItems,
                ContextMenuButtonItem(
                  onPressed: () {
                    selectableRegionState.hideToolbar();
                    _handleDefine();
                  },
                  label: 'Define',
                ),
                ContextMenuButtonItem(
                  onPressed: () {
                    selectableRegionState.hideToolbar();
                    _handleTranslate();
                  },
                  label: 'Translate',
                ),
              ];

              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: selectableRegionState.contextMenuAnchors,
                buttonItems: buttonItems,
              );
            },
            child: _buildBody(entry),
          );
        },
      ),
    );
  }

  Widget _buildBody(FeedEntry entry) {
    final fontSize = localDb.readerFontSize;
    final fontFamilyOption = localDb.readerFontFamily;

    String? currentFontFamily;
    switch (fontFamilyOption) {
      case 'serif':
        currentFontFamily = GoogleFonts.lora().fontFamily;
        break;
      case 'monospace':
        currentFontFamily = GoogleFonts.firaCode().fontFamily;
        break;
      case 'sans-serif':
      default:
        currentFontFamily = GoogleFonts.manrope().fontFamily;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: GoogleFonts.epilogue(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.surface1),
          SizedBox(height: 24),
          if (_isLoadingReaderMode)
            Center(
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
                    Icon(Icons.error_outline,
                        color: AppColors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Reader Mode Error',
                      style: GoogleFonts.epilogue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _readerModeError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.subtext1),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isReaderMode = false;
                          _readerModeError = null;
                        });
                      },
                      child: Text('Back to Normal View'),
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
                    Icon(Icons.info_outline, color: AppColors.subtext1),
                    SizedBox(width: 12),
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
              SizedBox(height: 24),
            ],
            Html(
              data: _isReaderMode ? (_readerModeContent ?? '') : entry.subtitle,
              extensions: [
                ImageExtension(
                  handleAssetImages: false,
                  handleDataImages: true,
                  handleNetworkImages: true,
                  builder: (extensionContext) {
                    final src = extensionContext.attributes['src'];
                    if (src == null) return SizedBox.shrink();
                    return Image.network(
                      src,
                      errorBuilder: (context, error, stackTrace) =>
                          SizedBox.shrink(),
                    );
                  },
                ),
              ],
              style: {
                "body": Style(
                  fontFamily: currentFontFamily,
                  fontSize: FontSize(fontSize),
                  color: AppColors.text,
                  lineHeight: LineHeight(1.8),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 24.0),
                  fontSize: FontSize(fontSize),
                  lineHeight: LineHeight(1.8),
                ),
                "a": Style(
                  color: AppColors.blue,
                  textDecoration: TextDecoration.underline,
                  textDecorationColor: AppColors.blue.withValues(alpha: 0.5),
                ),
                "img": Style(
                  width: Width(100, Unit.percent),
                  height: Height.auto(),
                  margin: Margins.only(top: 24.0, bottom: 8.0),
                ),
                "figcaption": Style(
                  fontFamily: GoogleFonts.manrope().fontFamily,
                  fontSize: FontSize(14.0),
                  color: AppColors.overlay0,
                  fontStyle: FontStyle.italic,
                  textAlign: TextAlign.center,
                  margin: Margins.only(bottom: 24.0),
                ),
                "blockquote": Style(
                  margin: Margins.only(left: 0.0, top: 24.0, bottom: 24.0),
                  padding: HtmlPaddings.only(
                      left: 20.0, top: 8.0, bottom: 8.0, right: 16.0),
                  border: Border(
                      left: BorderSide(color: AppColors.blue, width: 4.0)),
                  backgroundColor: AppColors.surface0.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                  color: AppColors.subtext1,
                ),
                "h1": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(32.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  margin: Margins.only(top: 32.0, bottom: 16.0),
                  color: AppColors.text,
                ),
                "h2": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(26.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  margin: Margins.only(top: 28.0, bottom: 12.0),
                  color: AppColors.text,
                ),
                "h3": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(22.0),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24.0, bottom: 10.0),
                  color: AppColors.text,
                ),
                "h4": Style(
                  fontFamily: GoogleFonts.epilogue().fontFamily,
                  fontSize: FontSize(18.0),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 20.0, bottom: 8.0),
                  color: AppColors.text,
                ),
                "pre": Style(
                  backgroundColor: AppColors.mantle,
                  padding: HtmlPaddings.all(16.0),
                  margin: Margins.only(top: 16.0, bottom: 16.0),
                  border: Border.all(color: AppColors.surface1),
                ),
                "code": Style(
                  fontFamily: GoogleFonts.firaCode().fontFamily,
                  backgroundColor: AppColors.mantle,
                  fontSize: FontSize(14.0),
                  color: AppColors.mauve,
                ),
                "ul": Style(
                  margin: Margins.only(bottom: 24.0),
                  padding: HtmlPaddings.only(left: 24.0),
                ),
                "ol": Style(
                  margin: Margins.only(bottom: 24.0),
                  padding: HtmlPaddings.only(left: 24.0),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 8.0),
                  lineHeight: LineHeight(1.6),
                ),
                "hr": Style(
                  margin: Margins.only(top: 32.0, bottom: 32.0),
                  border: Border(
                      bottom:
                          BorderSide(color: AppColors.surface1, width: 1.0)),
                ),
              },
            ),
          ],
          SizedBox(height: 48),
        ],
      ),
    );
  }
}