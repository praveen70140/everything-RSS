import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

void main() {
  Html(
    data: "test",
    extensions: [
      ImageExtension(),
    ],
  );
}
