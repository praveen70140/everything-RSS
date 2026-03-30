import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  SelectionArea(
    onSelectionChanged: (SelectedContent? content) {
      final t = content?.plainText;
    },
    child: Text('hello'),
  );
}
