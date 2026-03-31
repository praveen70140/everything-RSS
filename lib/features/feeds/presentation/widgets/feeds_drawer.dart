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
  bool _isAddFeedOpen = false;
  bool _isAddFolderOpen = false;
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
        ..name = _folderController.text.trim().toUpperCase()
        ..isExpanded = true
        ..sortOrder = _folders.length;

      await localDb.saveFolder(newFolder);

      _folderController.clear();
      setState(() {
        _isAddFolderOpen = false;
      });
      _loadData();
    }
  }

  Future<void> _addNewFeed() async {
    final url = _feedController.text.trim();
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
      setState(() {
        _isAddFeedOpen = false;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please add a third-party server first in settings.')),
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
            title: Text('Discover / Search',
                style: TextStyle(color: AppColors.text)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.rss_feed, color: AppColors.blue),
                  SizedBox(width: 8),
                  Text(
                    'FEEDS',
                    style: GoogleFonts.epilogue(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.all_inbox, color: AppColors.text),
              title: Text('All Feeds',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => widget.onFeedSelected(null, feedName: 'ALL FEEDS'),
            ),
            ListTile(
              leading: Icon(Icons.watch_later_outlined, color: AppColors.green),
              title:
                  Text('To do', style: TextStyle(fontWeight: FontWeight.bold)),
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
              leading: Icon(Icons.archive_outlined, color: AppColors.mauve),
              title: Text('Archive',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
            ListTile(
              leading: Icon(Icons.search, color: AppColors.blue),
              title: Text('Discover',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: _showSearchDialog,
            ),
            Divider(color: AppColors.surface1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.add_circle,
                      label: 'FEED',
                      onTap: () => setState(() {
                        _isAddFeedOpen = !_isAddFeedOpen;
                        _isAddFolderOpen = false;
                      }),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.create_new_folder,
                      label: 'FOLDER',
                      onTap: () => setState(() {
                        _isAddFolderOpen = !_isAddFolderOpen;
                        _isAddFeedOpen = false;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            _buildAnimatedForm(
              isOpen: _isAddFeedOpen,
              hintText: 'https://rss-link.com',
              controller: _feedController,
              onAdd: _addNewFeed,
              onCancel: () => setState(() => _isAddFeedOpen = false),
            ),
            _buildAnimatedForm(
              isOpen: _isAddFolderOpen,
              hintText: 'Folder Name',
              controller: _folderController,
              onAdd: _addNewFolder,
              onCancel: () => setState(() => _isAddFolderOpen = false),
            ),
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
                              ? AppColors.surface0.withOpacity(0.2)
                              : Colors.transparent,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                            children: [
                              ..._folders
                                  .map((folder) => _buildFolderTarget(folder)),
                              SizedBox(height: 8),
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
            ListTile(
              leading: Icon(Icons.hub, color: AppColors.blue, size: 20),
              title: Text(
                'Third-Party Servers',
                style: GoogleFonts.manrope(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ThirdPartyServersPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: AppColors.blue, size: 20),
              title: Text(
                'App Settings',
                style: GoogleFonts.manrope(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AppSettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface0,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blue, size: 16),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedForm({
    required bool isOpen,
    required String hintText,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required VoidCallback onCancel,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOpen ? 100 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.crust,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              TextField(
                controller: controller,
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: AppColors.overlay0),
                  filled: true,
                  fillColor: AppColors.base,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.surface1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
                onSubmitted: (_) => onAdd(),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: AppColors.base,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: onAdd,
                      child: Text('ADD',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: onCancel,
                    child: Text('CANCEL',
                        style: TextStyle(color: AppColors.text, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
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
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
              color: isHovered
                  ? AppColors.surface0.withOpacity(0.6)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
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
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              trailing: SizedBox.shrink(),
              leading: Icon(
                folder.isExpanded ? Icons.folder_open : Icons.folder,
                color: isHovered ? AppColors.blue : AppColors.mauve,
              ),
              title: Text(
                folder.name,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              iconColor: AppColors.overlay0,
              collapsedIconColor: AppColors.overlay0,
              children: folderFeeds
                  .map((feed) => Padding(
                        padding: const EdgeInsets.only(left: 12.0),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.rss_feed, color: AppColors.green, size: 20),
      title: Text(
        feed.name,
        style: TextStyle(color: AppColors.subtext1, fontSize: 14),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: AppColors.overlay0, size: 18),
        color: AppColors.surface1,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: Text('Rename',
                style: TextStyle(color: AppColors.text, fontSize: 12)),
          ),
          PopupMenuItem(
            value: 'archive',
            child: Text('View Archive',
                style: TextStyle(color: AppColors.text, fontSize: 12)),
          ),
          PopupMenuItem(
            value: 'todo',
            child: Text('View To-Do',
                style: TextStyle(color: AppColors.text, fontSize: 12)),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Text('Settings',
                style: TextStyle(color: AppColors.text, fontSize: 12)),
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
