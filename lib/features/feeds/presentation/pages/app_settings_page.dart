import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/background_tasks.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/local_db.dart';
import '../../data/repositories/opml_service.dart';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  ConsumerState<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends ConsumerState<AppSettingsPage> {
  late TextEditingController _mercuryUrlController;

  @override
  void initState() {
    super.initState();
    _mercuryUrlController =
        TextEditingController(text: localDb.mercuryParserUrl);
  }

  @override
  void dispose() {
    _mercuryUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final url = _mercuryUrlController.text.trim();
    if (url.isNotEmpty) {
      await localDb.setMercuryParserUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    }
  }

  Future<void> _importOpml() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String xmlString = await file.readAsString();
        await OpmlService.importOpml(xmlString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OPML imported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import OPML: $e')),
        );
      }
    }
  }

  Future<void> _exportOpml() async {
    try {
      String xmlString = await OpmlService.exportOpml();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/feeds.opml');
      await file.writeAsString(xmlString);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'My RSS Feeds OPML Export',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export OPML: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.crust,
      appBar: AppBar(
        backgroundColor: AppColors.crust,
        title: Text(
          'App Settings',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Appearance',
            style: GoogleFonts.epilogue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text('Dark Mode', style: TextStyle(color: AppColors.text)),
            value: isDark,
            activeColor: AppColors.blue,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          SizedBox(height: 32),
          Text(
            'Reader Mode',
            style: GoogleFonts.epilogue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Configure the URL for the Mercury Parser API used to extract full article text.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _mercuryUrlController,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              labelText: 'Mercury Parser URL',
              labelStyle: TextStyle(color: AppColors.overlay0),
              hintText: 'http://10.0.2.2:3000',
              hintStyle: TextStyle(color: AppColors.overlay0),
              filled: true,
              fillColor: AppColors.base,
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
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 8),
          Text(
            'Tip: Use http://10.0.2.2:3000 for local Docker on Android emulator.',
            style: GoogleFonts.manrope(
              color: AppColors.overlay0,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.base,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _saveSettings,
            child: Text(
              'Save Settings',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Background Tasks',
            style: GoogleFonts.epilogue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manually trigger the auto-download service for feeds that have it enabled.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface0,
              foregroundColor: AppColors.text,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.download_for_offline, color: AppColors.blue),
            label: Text(
              'Trigger Auto-Downloads Now',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Starting background downloads...')),
              );
              await BackgroundTasks.runAutoDownloads(checkTime: false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-downloads triggered')),
                );
              }
            },
          ),
          SizedBox(height: 32),
          Text(
            'Feed Management',
            style: GoogleFonts.epilogue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Import or export your subscriptions using OPML files.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.file_upload),
                  label: Text('Import OPML'),
                  onPressed: _importOpml,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.surface1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.file_download),
                  label: Text('Export OPML'),
                  onPressed: _exportOpml,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.surface1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
