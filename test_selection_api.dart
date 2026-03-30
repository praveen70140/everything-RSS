import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  String? _selectedText;
  SelectionArea(
    onSelectionChanged: (SelectedContent? content) {
      _selectedText = content?.plainText;
    },
    contextMenuBuilder: (context, selectableRegionState) {
      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: selectableRegionState.contextMenuAnchors,
        buttonItems: [
          ...selectableRegionState.contextMenuButtonItems,
          ContextMenuButtonItem(
            onPressed: () {
              print('Define $_selectedText');
            },
            label: 'Define',
          ),
        ],
      );
    },
    child: Text('hello'),
  );
}
