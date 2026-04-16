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
import '../utils/url_validation.dart';

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
    final validation = validateHttpUrl(_mercuryUrlController.text);
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validation.message!)),
        );
      }
      return;
    }

    await localDb.setMercuryParserUrl(validation.normalizedUrl!);
    _mercuryUrlController.text = validation.normalizedUrl!;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mercury Parser URL saved.'),
        ),
      );
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
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'My RSS Feeds OPML Export',
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          ),
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
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        title: Text(
          'App Settings',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.surface1, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: Text('Dark Mode', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
            subtitle: Text('Toggle Catppuccin Mocha/Latte themes', style: TextStyle(color: AppColors.subtext1, fontSize: 12)),
            value: isDark,
            activeColor: AppColors.blue,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Mercury Parser (Full-text)'),
          const SizedBox(height: 8),
          Text(
            'Connect a self-hosted Mercury Parser instance to extract full article content from abbreviated RSS feeds.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mercuryUrlController,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              labelText: 'Mercury Parser URL',
              labelStyle: TextStyle(color: AppColors.overlay0),
              hintText: 'http://10.0.2.2:3000',
              hintStyle: TextStyle(color: AppColors.overlay0),
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
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Use http://10.0.2.2:3000 for local Docker on Android emulator.',
            style: GoogleFonts.manrope(
              color: AppColors.overlay0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
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
              'Save Mercury Server',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Background Tasks'),
          const SizedBox(height: 8),
          Text(
            'Trigger the auto-download service to fetch content for offline access.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
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
              'Trigger Auto-Downloads',
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
          const SizedBox(height: 32),
          _buildSectionHeader('Subscription Management (OPML)'),
          const SizedBox(height: 8),
          Text(
            'Import or export your subscriptions using standard OPML files.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import'),
                  onPressed: _importOpml,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.surface1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export'),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.epilogue(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }
}
