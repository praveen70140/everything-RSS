import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/local_db.dart';
import '../../data/models/local_feed_folder.dart';
import '../../data/models/local_feed_item.dart';
import '../../data/models/third_party_server.dart';
import '../pages/app_settings_page.dart';
import '../pages/feed_settings_page.dart';
import '../pages/saved_feeds_page.dart';
import '../pages/third_party_servers_page.dart';
import '../utils/url_validation.dart';

class FeedsDrawer extends StatefulWidget {
  final Function(String? url, {String? feedName}) onFeedSelected;

  const FeedsDrawer({
    super.key,
    required this.onFeedSelected,
  });

  @override
  State<FeedsDrawer> createState() => _FeedsDrawerState();
}

class _FeedsDrawerState extends State<FeedsDrawer> {
  bool _isLoading = true;

  final TextEditingController _feedController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();

  List<LocalFeedFolder> _folders = [];
  List<LocalFeedItem> _feeds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final folders = await localDb.getFolders();
    final feeds = await localDb.getFeeds();

    if (mounted) {
      setState(() {
        _folders = folders;
        _feeds = feeds;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewFolder() async {
    if (_folderController.text.trim().isNotEmpty) {
      final newFolder = LocalFeedFolder()
        ..name = _folderController.text.trim()
        ..isExpanded = true
        ..sortOrder = _folders.length;

      await localDb.saveFolder(newFolder);

      _folderController.clear();
      _loadData();
    }
  }

  Future<void> _addNewFeed(String url) async {
    if (url.isNotEmpty) {
      String name = 'New Feed';
      try {
        final uri = Uri.parse(url);
        if (uri.host.isNotEmpty) {
          name = uri.host.replaceFirst('www.', '');
        }
      } catch (_) {}

      final newFeed = LocalFeedItem()
        ..name = name
        ..url = url
        ..folderId = null
        ..sortOrder = _feeds.where((f) => f.folderId == null).length;

      await localDb.saveFeed(newFeed);

      _feedController.clear();
      _loadData();

      widget.onFeedSelected(url);
    }
  }

  Future<void> _updateFeedOrder(LocalFeedItem draggedFeed,
      LocalFeedItem? targetFeed, int? newFolderId) async {
    setState(() {
      _feeds.removeWhere((f) => f.id == draggedFeed.id);

      draggedFeed.folderId = newFolderId;

      if (targetFeed != null) {
        int targetIndex = _feeds.indexWhere((f) => f.id == targetFeed.id);
        if (targetIndex != -1) {
          _feeds.insert(targetIndex, draggedFeed);
        } else {
          _feeds.add(draggedFeed);
        }
      } else {
        _feeds.add(draggedFeed);
      }

      // Update sortOrder for all affected feeds
      List<LocalFeedItem> feedsInFolder =
          _feeds.where((f) => f.folderId == newFolderId).toList();
      for (int i = 0; i < feedsInFolder.length; i++) {
        feedsInFolder[i].sortOrder = i;
      }
    });

    // Save batch to database
    await localDb
        .saveFeeds(_feeds.where((f) => f.folderId == newFolderId).toList());
  }

  Future<void> _showRenameDialog(LocalFeedItem feed) async {
    final TextEditingController renameController =
        TextEditingController(text: feed.name);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.base,
          title: Text('Rename Feed', style: TextStyle(color: AppColors.text)),
          content: TextField(
            controller: renameController,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Feed Name',
              hintStyle: TextStyle(color: AppColors.overlay0),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.surface1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.blue),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Cancel', style: TextStyle(color: AppColors.subtext1)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
              onPressed: () async {
                final newName = renameController.text.trim();
                if (newName.isNotEmpty) {
                  feed.name = newName;
                  await feed.save();
                  _loadData();
                }
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: AppColors.base)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSearchDialog() async {
    final servers = await localDb.getThirdPartyServers();
    if (servers.isEmpty) {
      if (mounted) {
        final drawerNavigator = Navigator.of(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.base,
            title: Text('Setup discovery server',
                style: TextStyle(color: AppColors.text)),
            content: Text(
              'Discovery requires a self-hosted instance of RSSHub or a yt-dlp-RSS proxy. Configure one in Servers first.',
              style: TextStyle(color: AppColors.subtext1),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('Cancel', style: TextStyle(color: AppColors.subtext1)),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  drawerNavigator.pop();
                  drawerNavigator.push(
                    MaterialPageRoute(
                      builder: (_) => const ThirdPartyServersPage(),
                    ),
                  );
                },
                child:
                    Text('Go to Servers', style: TextStyle(color: AppColors.base)),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    ThirdPartyServer selectedServer = servers.first;
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.base,
            title:
                Text('Discover feeds', style: TextStyle(color: AppColors.text)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose the source server to search, then enter a topic or channel.',
                  style: TextStyle(color: AppColors.subtext1),
                ),
                SizedBox(height: 12),
                DropdownButton<ThirdPartyServer>(
                  value: selectedServer,
                  isExpanded: true,
                  dropdownColor: AppColors.surface0,
                  style: TextStyle(color: AppColors.text),
                  items: servers.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedServer = val);
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Enter search term...',
                    hintStyle: TextStyle(color: AppColors.overlay0),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.surface1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.blue),
                    ),
                  ),
                  autofocus: true,
                  onSubmitted: (_) {
                    Navigator.pop(context);
                    _performSearch(selectedServer, searchController.text);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('Cancel', style: TextStyle(color: AppColors.subtext1)),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  _performSearch(selectedServer, searchController.text);
                },
                child: Text('Search', style: TextStyle(color: AppColors.base)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _performSearch(ThirdPartyServer server, String term) async {
    if (term.isEmpty) return;

    final baseUrl = server.url.endsWith('/')
        ? server.url.substring(0, server.url.length - 1)
        : server.url;
    final searchUrl = '$baseUrl/search?q=${Uri.encodeComponent(term)}';

    // Close drawer
    Navigator.pop(context);

    // Load search results as a feed
    widget.onFeedSelected(searchUrl, feedName: 'Search: $term');
  }

  @override
  void dispose() {
    _feedController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.base,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                children: [
                  Icon(Icons.rss_feed, color: AppColors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Everything RSS',
                    style: GoogleFonts.epilogue(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionLabel('READING'),
            ListTile(
              leading: Icon(Icons.all_inbox, color: AppColors.text, size: 22),
              title: Text('All Feeds',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              onTap: () => widget.onFeedSelected(null, feedName: 'All Feeds'),
            ),
            ListTile(
              leading: Icon(Icons.watch_later_outlined, color: AppColors.green, size: 22),
              title:
                  Text('To do', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedFeedsPage(
                      status: 'todo',
                      feedName: 'All Read Later',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.archive_outlined, color: AppColors.mauve, size: 22),
              title: Text('Archive',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedFeedsPage(
                      status: 'archive',
                      feedName: 'All Archived',
                    ),
                  ),
                );
              },
            ),
            Divider(color: AppColors.surface1, indent: 16, endIndent: 16, height: 24),
            _buildSectionLabel('SOURCES'),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.blue))
                  : DragTarget<LocalFeedItem>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        _updateFeedOrder(details.data, null, null);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          color: candidateData.isNotEmpty
                              ? AppColors.surface0.withValues(alpha: 0.2)
                              : Colors.transparent,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            children: [
                              ..._folders
                                  .map((folder) => _buildFolderTarget(folder)),
                              SizedBox(height: 4),
                              ..._feeds
                                  .where((f) => f.folderId == null)
                                  .map((feed) => _buildDraggableFeed(feed)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: AppColors.surface1),
            _buildSectionLabel('MANAGE'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.add_link,
                      label: 'Add Feed',
                      onTap: _showAddFeedSheet,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.create_new_folder_outlined,
                      label: 'New Folder',
                      onTap: _showAddFolderSheet,
                    ),
                  ),
                ],
              ),
            ),
            _buildManageTile(
              icon: Icons.search,
              label: 'Discover Feeds',
              onTap: _showSearchDialog,
            ),
            _buildManageTile(
              icon: Icons.hub_outlined,
              label: 'Servers (RSSHub, yt-dlp)',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ThirdPartyServersPage()),
                );
              },
            ),
            _buildManageTile(
              icon: Icons.settings_outlined,
              label: 'App Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AppSettingsPage()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: AppColors.overlay0,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildManageTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.subtext1, size: 20),
      title: Text(
        label,
        style: GoogleFonts.manrope(
          color: AppColors.text,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface1.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blue, size: 18),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFeedSheet() {
    _feedController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crust,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? errorText;

        Future<void> submit(StateSetter setModalState) async {
          final validation = validateHttpUrl(_feedController.text);
          if (!validation.isValid) {
            setModalState(() => errorText = validation.message);
            return;
          }

          Navigator.pop(context);
          await _addNewFeed(validation.normalizedUrl!);
        }

        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add feed',
                  style: GoogleFonts.epilogue(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste an RSS, Atom, or website feed link.',
                  style: TextStyle(color: AppColors.subtext1),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedController,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Feed URL',
                    errorText: errorText,
                    hintText: 'https://example.com/feed.xml',
                    hintStyle: TextStyle(color: AppColors.overlay0),
                    filled: true,
                    fillColor: AppColors.base,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.surface1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  autofocus: true,
                  onChanged: (_) {
                    if (errorText != null) {
                      setModalState(() => errorText = null);
                    }
                  },
                  onSubmitted: (_) => submit(setModalState),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => submit(setModalState),
                    child: Text(
                      'Add feed',
                      style: TextStyle(
                        color: AppColors.base,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  void _showAddFolderSheet() {
    _folderController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crust,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create folder',
              style: GoogleFonts.epilogue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _folderController,
              style: TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Folder Name',
                hintStyle: TextStyle(color: AppColors.overlay0),
                filled: true,
                fillColor: AppColors.base,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.surface1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.blue),
                ),
              ),
              autofocus: true,
              onSubmitted: (_) {
                Navigator.pop(context);
                _addNewFolder();
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _addNewFolder();
                },
                child: Text(
                  'Create folder',
                  style: TextStyle(
                    color: AppColors.base,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTarget(LocalFeedFolder folder) {
    final folderFeeds = _feeds.where((f) => f.folderId == folder.id).toList();

    return DragTarget<LocalFeedItem>(
      onWillAcceptWithDetails: (details) => details.data.folderId != folder.id,
      onAcceptWithDetails: (details) async {
        await _updateFeedOrder(details.data, null, folder.id);
        setState(() {
          folder.isExpanded = true;
        });
        localDb.saveFolder(folder);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
              color: isHovered
                  ? AppColors.surface0.withValues(alpha: 0.6)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovered ? AppColors.blue : Colors.transparent,
              )),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              listTileTheme: const ListTileThemeData(
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: folder.isExpanded,
              onExpansionChanged: (val) {
                setState(() => folder.isExpanded = val);
                localDb.saveFolder(folder);
              },
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              trailing: Icon(
                folder.isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: AppColors.overlay0,
              ),
              leading: Icon(
                folder.isExpanded ? Icons.folder_open : Icons.folder,
                color: isHovered ? AppColors.blue : AppColors.mauve,
                size: 22,
              ),
              title: Text(
                folder.name,
                style: GoogleFonts.manrope(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconColor: AppColors.overlay0,
              collapsedIconColor: AppColors.overlay0,
              children: folderFeeds
                  .map((feed) => Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: _buildDraggableFeed(feed),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableFeed(LocalFeedItem feed) {
    return DragTarget<LocalFeedItem>(
      onWillAcceptWithDetails: (details) => details.data.id != feed.id,
      onAcceptWithDetails: (details) {
        _updateFeedOrder(details.data, feed, feed.folderId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            border: isHovered
                ? Border(top: BorderSide(color: AppColors.blue, width: 2))
                : Border(top: BorderSide(color: Colors.transparent, width: 2)),
          ),
          child: LongPressDraggable<LocalFeedItem>(
            data: feed,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface0,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.rss_feed, color: AppColors.green, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feed.name,
                        style: TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildFeedTile(feed),
            ),
            child: _buildFeedTile(feed),
          ),
        );
      },
    );
  }

  Widget _buildFeedTile(LocalFeedItem feed) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(Icons.rss_feed, color: AppColors.green, size: 18),
      title: Text(
        feed.name,
        style: GoogleFonts.manrope(
          color: AppColors.subtext1,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: AppColors.overlay0, size: 18),
        color: AppColors.surface1,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: Text('Rename',
                style: TextStyle(color: AppColors.text, fontSize: 13)),
          ),
          PopupMenuItem(
            value: 'archive',
            child: Text('View Archive',
                style: TextStyle(color: AppColors.text, fontSize: 13)),
          ),
          PopupMenuItem(
            value: 'todo',
            child: Text('View To-Do',
                style: TextStyle(color: AppColors.text, fontSize: 13)),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Text('Settings',
                style: TextStyle(color: AppColors.text, fontSize: 13)),
          ),
        ],
        onSelected: (value) {
          // Close drawer
          Navigator.pop(context);

          if (value == 'rename') {
            _showRenameDialog(feed);
          } else if (value == 'settings') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FeedSettingsPage(feed: feed),
              ),
            );
          } else {
            // Navigate to saved page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SavedFeedsPage(
                  feedUrl: feed.url,
                  status: value,
                  feedName: feed.name,
                ),
              ),
            );
          }
        },
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: () => widget.onFeedSelected(feed.url, feedName: feed.name),
    );
  }
}
