import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:everything_rss/core/theme/app_colors.dart';

class ErrorState extends StatefulWidget {
  final String title;
  final String message;
  final String? details;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<ErrorState> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.epilogue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: TextStyle(color: AppColors.subtext1),
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface0,
                  foregroundColor: AppColors.text,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: widget.onAction,
                child: Text(widget.actionLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            if (widget.details != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                child: Text(
                  _showDetails ? 'Hide Technical Details' : 'Show Technical Details',
                  style: TextStyle(color: AppColors.overlay0, fontSize: 12),
                ),
              ),
              if (_showDetails)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.crust,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surface1),
                  ),
                  child: Text(
                    widget.details!,
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: AppColors.subtext1,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
