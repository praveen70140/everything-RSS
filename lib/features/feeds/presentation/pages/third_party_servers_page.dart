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

  Future<void> _addOrUpdateServer(String url, String name,
      {ThirdPartyServer? existingServer}) async {
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    // Ensure URL has http/https scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      // Fetch links.txt
      final linkTxtUrl =
          url.endsWith('/') ? '${url}links.txt' : '$url/links.txt';
      final response = await http.get(Uri.parse(linkTxtUrl));

      List<String> domains = [];
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

      final server = existingServer ??
          ThirdPartyServer(
            id: const Uuid().v4(),
            url: url,
            name: name.isEmpty ? Uri.parse(url).host : name,
          );

      server.url = url;
      server.name = name.isEmpty ? server.name : name;
      server.supportedDomains = domains;

      await localDb.saveThirdPartyServer(server);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Server added/updated successfully with ${domains.length} domains')),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(server == null ? 'Add Third-Party Server' : 'Edit Server'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (Optional)',
                  hintText: 'My RSS Proxy',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://proxy.example.com',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addOrUpdateServer(urlController.text, nameController.text,
                    existingServer: server);
              },
              child: Text('Save'),
            ),
          ],
        );
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
          ? Center(child: CircularProgressIndicator())
          : _servers.isEmpty
              ? Center(child: Text('No third-party servers added yet.'))
              : ListView.builder(
                  itemCount: _servers.length,
                  itemBuilder: (context, index) {
                    final server = _servers[index];
                    return ListTile(
                      title: Text(server.name),
                      subtitle: Text(
                          '${server.url}\n${server.supportedDomains.length} domains supported'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.refresh),
                            tooltip: 'Refresh links.txt',
                            onPressed: () => _addOrUpdateServer(
                                server.url, server.name,
                                existingServer: server),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteServer(server),
                          ),
                        ],
                      ),
                      onTap: () => _showAddServerDialog(server: server),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServerDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Server',
      ),
    );
  }
}
