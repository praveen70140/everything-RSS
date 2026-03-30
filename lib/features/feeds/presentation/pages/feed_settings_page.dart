import 'package:flutter/material.dart';
import '../../../../core/database/local_db.dart';
import '../../data/models/local_feed_item.dart';
import '../../../../core/theme/app_colors.dart';

class FeedSettingsPage extends StatefulWidget {
  final LocalFeedItem feed;

  const FeedSettingsPage({super.key, required this.feed});

  @override
  State<FeedSettingsPage> createState() => _FeedSettingsPageState();
}

class _FeedSettingsPageState extends State<FeedSettingsPage> {
  late bool autoDownload;
  late bool requireWiFi;
  late String? autoDownloadTime;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    autoDownload = widget.feed.autoDownload;
    requireWiFi = widget.feed.requireWiFi;
    autoDownloadTime = widget.feed.autoDownloadTime;
    _nameController = TextEditingController(text: widget.feed.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    widget.feed.name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.feed.name;
    widget.feed.autoDownload = autoDownload;
    widget.feed.requireWiFi = requireWiFi;
    widget.feed.autoDownloadTime = autoDownloadTime;
    await widget.feed.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully.')),
      );
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (autoDownloadTime != null && autoDownloadTime!.isNotEmpty) {
      final parts = autoDownloadTime!.split(':');
      if (parts.length == 2) {
        initialTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        autoDownloadTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: Text('${widget.feed.name} Settings'),
        backgroundColor: AppColors.mantle,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(color: AppColors.text, fontSize: 20),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              labelText: 'Feed Name',
              labelStyle: TextStyle(color: AppColors.overlay0),
              filled: true,
              fillColor: AppColors.crust,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.surface1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.surface1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.blue),
              ),
            ),
            onSubmitted: (_) => _saveSettings(),
          ),
          SizedBox(height: 24),
          SwitchListTile(
            title: Text('Auto-Download Media',
                style: TextStyle(color: AppColors.text)),
            subtitle: Text(
                'Automatically download video and audio for new feed items',
                style: TextStyle(color: AppColors.subtext1)),
            value: autoDownload,
            onChanged: (val) {
              setState(() => autoDownload = val);
              _saveSettings();
            },
            activeColor: AppColors.green,
          ),
          if (autoDownload) ...[
            SwitchListTile(
              title: Text('Require Wi-Fi',
                  style: TextStyle(color: AppColors.text)),
              subtitle: Text(
                  'Only download when connected to a Wi-Fi network',
                  style: TextStyle(color: AppColors.subtext1)),
              value: requireWiFi,
              onChanged: (val) {
                setState(() => requireWiFi = val);
                _saveSettings();
              },
              activeColor: AppColors.green,
            ),
            ListTile(
              title: Text('Scheduled Time',
                  style: TextStyle(color: AppColors.text)),
              subtitle: Text(
                  autoDownloadTime != null ? autoDownloadTime! : 'Not set',
                  style: TextStyle(color: AppColors.subtext1)),
              trailing:
                  Icon(Icons.access_time, color: AppColors.overlay0),
              onTap: _pickTime,
            ),
          ],
        ],
      ),
    );
  }
}