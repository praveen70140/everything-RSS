import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    autoDownload = widget.feed.autoDownload;
    requireWiFi = widget.feed.requireWiFi;
    autoDownloadTime = widget.feed.autoDownloadTime;
  }

  Future<void> _saveSettings({bool showConfirmation = false}) async {
    widget.feed.autoDownload = autoDownload;
    widget.feed.requireWiFi = requireWiFi;
    widget.feed.autoDownloadTime = autoDownloadTime;
    await widget.feed.save();
    if (mounted && showConfirmation) {
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
      backgroundColor: AppColors.crust,
      appBar: AppBar(
        title: Text('${widget.feed.name} Settings'),
        backgroundColor: AppColors.crust,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            activeThumbColor: AppColors.green,
          ),
          if (autoDownload) ...[
            SwitchListTile(
              title: Text('Require Wi-Fi',
                  style: TextStyle(color: AppColors.text)),
              subtitle: Text('Only download when connected to a Wi-Fi network',
                  style: TextStyle(color: AppColors.subtext1)),
              value: requireWiFi,
              onChanged: (val) {
                setState(() => requireWiFi = val);
                _saveSettings();
              },
              activeThumbColor: AppColors.green,
            ),
            ListTile(
              title: Text('Scheduled Time',
                  style: TextStyle(color: AppColors.text)),
              subtitle: Text(
                  autoDownloadTime != null ? autoDownloadTime! : 'Not set',
                  style: TextStyle(color: AppColors.subtext1)),
              trailing: Icon(Icons.access_time, color: AppColors.overlay0),
              onTap: _pickTime,
            ),
          ],
        ],
      ),
    );
  }
}
