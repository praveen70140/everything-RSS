import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/local_db.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late TextEditingController _mercuryUrlController;

  @override
  void initState() {
    super.initState();
    _mercuryUrlController = TextEditingController(text: localDb.mercuryParserUrl);
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

  @override
  Widget build(BuildContext context) {
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
            'Reader Mode',
            style: GoogleFonts.epilogue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure the URL for the Mercury Parser API used to extract full article text.',
            style: GoogleFonts.manrope(
              color: AppColors.subtext1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mercuryUrlController,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              labelText: 'Mercury Parser URL',
              labelStyle: const TextStyle(color: AppColors.overlay0),
              hintText: 'http://10.0.2.2:3000',
              hintStyle: const TextStyle(color: AppColors.overlay0),
              filled: true,
              fillColor: AppColors.base,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surface1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surface1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.blue),
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
              'Save Settings',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
