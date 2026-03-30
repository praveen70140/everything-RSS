import 'dart:io';

void main() {
  final file = File('analyze_out.txt');
  if (!file.existsSync()) return;
  final lines = file.readAsLinesSync();

  for (var line in lines) {
    if (line.contains('Invalid constant value') && line.contains('.dart:')) {
      final match = RegExp(r'• (lib/[^:]+):(\d+):(\d+) •').firstMatch(line);
      if (match != null) {
        final filePath = match.group(1)!;
        final lineNumber = int.tryParse(match.group(2)!) ?? 0;

        if (lineNumber > 0) {
          final dartFile = File(filePath);
          if (dartFile.existsSync()) {
            final fileLines = dartFile.readAsLinesSync();
            final lineIndex = lineNumber - 1;
            if (lineIndex < fileLines.length) {
              String originalLine = fileLines[lineIndex];
              String updatedLine = originalLine.replaceFirst('const ', '');
              // Try regex to replace any "const " that isn't preceded by something else
              updatedLine = updatedLine.replaceAll(RegExp(r'\bconst\s+'), '');
              fileLines[lineIndex] = updatedLine;
              dartFile.writeAsStringSync(fileLines.join('\n'));
              print('Fixed $filePath:$lineNumber');
            }
          }
        }
      }
    }
  }
}
