import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

Widget buildHtml() {
  return Html(
    data: "test",
    extensions: [
      ImageExtension(
        handleAssetImages: false,
        handleDataImages: true,
        handleNetworkImages: true,
      ),
    ],
  );
}
