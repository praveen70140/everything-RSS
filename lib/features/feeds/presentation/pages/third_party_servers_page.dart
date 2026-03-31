import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../../core/database/local_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/third_party_server.dart';

class ThirdPartyServersPage extends StatefulWidget {
  const ThirdPartyServersPage({Key? key}) : super(key: key);

  @override
  State<ThirdPartyServersPage> createState() => _ThirdPartyServersPageState();
}

class _ThirdPartyServersPageState extends State<ThirdPartyServersPage> {
  List<ThirdPartyServer> _servers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);
    final servers = await localDb.getThirdPartyServers();
    setState(() {
      _servers = servers;
      _isLoading = false;
    });
  }

  Future<void> _addOrUpdateServer(String url, String name, String serverType,
      {ThirdPartyServer? existingServer}) async {
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    // Ensure URL has http/https scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      List<String> domains = [];

      if (serverType == 'ytdlp') {
        // Fetch links.txt for yt-dlp-RSS servers
        final linkTxtUrl =
            url.endsWith('/') ? '${url}links.txt' : '$url/links.txt';
        final response = await http.get(Uri.parse(linkTxtUrl));

        if (response.statusCode == 200) {
          domains = response.body
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          throw Exception(
              'Failed to load links.txt (Status: ${response.statusCode})');
        }
      } else if (serverType == 'rsshub') {
        // RSSHub supports hundreds of domains natively via routing, no need to fetch links.txt
        domains = ['*']; // We'll handle routing logic in getProxyUrl
      }

      final server = existingServer ??
          ThirdPartyServer(
            id: const Uuid().v4(),
            url: url,
            name: name.isEmpty ? Uri.parse(url).host : name,
            serverType: serverType,
          );

      server.url = url;
      server.name = name.isEmpty ? server.name : name;
      server.supportedDomains = domains;
      server.serverType = serverType;

      await localDb.saveThirdPartyServer(server);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Server added/updated successfully. Type: $serverType')),
        );
      }

      _loadServers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding server: $e')),
        );
      }
    }
  }

  Future<void> _deleteServer(ThirdPartyServer server) async {
    await localDb.deleteThirdPartyServer(server.id);
    _loadServers();
  }

  void _showAddServerDialog({ThirdPartyServer? server}) {
    final urlController = TextEditingController(text: server?.url);
    final nameController = TextEditingController(text: server?.name);
    String selectedType = server?.serverType ?? 'ytdlp';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.base,
            title: Text(
                server == null ? 'Add Third-Party Server' : 'Edit Server',
                style: TextStyle(color: AppColors.text)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  dropdownColor: AppColors.surface0,
                  style: TextStyle(color: AppColors.text),
                  items: const [
                    DropdownMenuItem(
                      value: 'ytdlp',
                      child: Text('yt-dlp-RSS Proxy'),
                    ),
                    DropdownMenuItem(
                      value: 'rsshub',
                      child: Text('RSSHub Proxy'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Name (Optional)',
                    labelStyle: TextStyle(color: AppColors.overlay0),
                    hintText: 'My Proxy',
                    hintStyle: TextStyle(color: AppColors.surface1),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.surface1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    labelStyle: TextStyle(color: AppColors.overlay0),
                    hintText: selectedType == 'rsshub'
                        ? 'https://rsshub.app'
                        : 'https://proxy.example.com',
                    hintStyle: TextStyle(color: AppColors.surface1),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.surface1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.url,
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
                  _addOrUpdateServer(
                      urlController.text, nameController.text, selectedType,
                      existingServer: server);
                },
                child: Text('Save', style: TextStyle(color: AppColors.base)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Third-Party Servers',
          style: GoogleFonts.epilogue(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.surface1, height: 1.0),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _servers.isEmpty
              ? Center(
                  child: Text('No third-party servers added yet.',
                      style: TextStyle(color: AppColors.subtext1)))
              : ListView.builder(
                  itemCount: _servers.length,
                  itemBuilder: (context, index) {
                    final server = _servers[index];
                    return ListTile(
                      title: Text(server.name,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Type: ${server.serverType}\nURL: ${server.url}',
                          style: TextStyle(color: AppColors.subtext1)),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (server.serverType == 'ytdlp')
                            IconButton(
                              icon: Icon(Icons.refresh, color: AppColors.blue),
                              tooltip: 'Refresh links.txt',
                              onPressed: () => _addOrUpdateServer(
                                  server.url, server.name, server.serverType,
                                  existingServer: server),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete, color: AppColors.red),
                            onPressed: () => _deleteServer(server),
                          ),
                        ],
                      ),
                      onTap: () => _showAddServerDialog(server: server),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: () => _showAddServerDialog(),
        child: Icon(Icons.add, color: AppColors.base),
        tooltip: 'Add Server',
      ),
    );
  }
}
