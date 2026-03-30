import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Html(
        data: "<img src='https://example.com/test.jpg' />",
        extensions: [
          ImageExtension(
            builder: (context) {
              return Image.network(context.attributes['src'] ?? '');
            }
          ),
        ],
      ),
    ),
  ));
}
