import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/database/local_db.dart';
import 'features/feeds/presentation/pages/feeds_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar Local Database
  await localDb.init();
  
  runApp(const EverythingRSSApp());
}

class EverythingRSSApp extends StatelessWidget {
  const EverythingRSSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everything RSS',
      theme: AppTheme.darkTheme,
      home: const FeedsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
