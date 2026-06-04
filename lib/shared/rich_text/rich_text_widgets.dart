import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:vesper/shared/rich_text/rich_text_delta.dart';

quill.QuillController richTextControllerFromDeltaJson(
  String deltaJson, {
  bool readOnly = false,
}) {
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is List) {
      return quill.QuillController(
        document: quill.Document.fromJson(decoded),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      );
    }
  } on FormatException {
    // Fall back to an empty document below.
  }
  return quill.QuillController(
    document: quill.Document.fromJson(
      jsonDecode(emptyRichTextDeltaJson()) as List,
    ),
    selection: const TextSelection.collapsed(offset: 0),
    readOnly: readOnly,
  );
}

String richTextControllerToDeltaJson(quill.QuillController controller) {
  return jsonEncode(controller.document.toDelta().toJson());
}

quill.Attribute richTextFormatAttributeForToggle(
  quill.QuillController controller,
  quill.Attribute attribute,
) {
  final activeAttribute = controller
      .getSelectionStyle()
      .attributes[attribute.key];
  final isActive =
      activeAttribute != null &&
      (activeAttribute.value == attribute.value || attribute.value == true);
  return isActive ? quill.Attribute.clone(attribute, null) : attribute;
}

class RichTextContentViewer extends StatelessWidget {
  const RichTextContentViewer({super.key, required this.deltaJson});

  final String deltaJson;

  @override
  Widget build(BuildContext context) {
    final controller = richTextControllerFromDeltaJson(
      deltaJson,
      readOnly: true,
    );
    return quill.QuillEditor.basic(
      controller: controller,
      focusNode: FocusNode(),
      scrollController: ScrollController(),
      config: const quill.QuillEditorConfig(
        scrollable: false,
        padding: EdgeInsets.zero,
        autoFocus: false,
        enableInteractiveSelection: false,
      ),
    );
  }
}

class RichTextContentEditor extends StatelessWidget {
  const RichTextContentEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    this.minHeight = 160,
    this.maxHeight = 320,
  });

  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return quill.QuillEditor.basic(
      controller: controller,
      focusNode: focusNode,
      scrollController: scrollController,
      config: quill.QuillEditorConfig(
        scrollable: true,
        padding: EdgeInsets.zero,
        autoFocus: false,
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
    );
  }
}

class RichTextFormatToolbar extends StatefulWidget {
  const RichTextFormatToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.busy = false,
  });

  final quill.QuillController controller;
  final FocusNode focusNode;
  final bool busy;

  @override
  State<RichTextFormatToolbar> createState() => _RichTextFormatToolbarState();
}

class _RichTextFormatToolbarState extends State<RichTextFormatToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(RichTextFormatToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _formatButton(
          context: context,
          tooltip: 'Bold',
          icon: const Icon(Icons.format_bold),
          attribute: quill.Attribute.bold,
        ),
        _formatButton(
          context: context,
          tooltip: 'Italic',
          icon: const Icon(Icons.format_italic),
          attribute: quill.Attribute.italic,
        ),
        _formatButton(
          context: context,
          tooltip: 'Strikethrough',
          icon: const Icon(Icons.format_strikethrough),
          attribute: quill.Attribute.strikeThrough,
        ),
        _formatButton(
          context: context,
          tooltip: 'Quote',
          icon: const Icon(Icons.format_quote),
          attribute: quill.Attribute.blockQuote,
        ),
        _formatButton(
          context: context,
          tooltip: 'Bulleted list',
          icon: const Icon(Icons.format_list_bulleted),
          attribute: quill.Attribute.ul,
        ),
        _formatButton(
          context: context,
          tooltip: 'Numbered list',
          icon: const Icon(Icons.format_list_numbered),
          attribute: quill.Attribute.ol,
        ),
      ],
    );
  }

  Widget _formatButton({
    required BuildContext context,
    required String tooltip,
    required Icon icon,
    required quill.Attribute attribute,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _isActive(attribute);
    return IconButton(
      tooltip: tooltip,
      isSelected: isActive,
      onPressed: widget.busy ? null : () => _format(attribute),
      icon: icon,
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? colorScheme.primaryContainer
            : Colors.transparent,
        foregroundColor: isActive
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
    );
  }

  bool _isActive(quill.Attribute attribute) {
    final activeAttribute = widget.controller
        .getSelectionStyle()
        .attributes[attribute.key];
    return activeAttribute != null &&
        (activeAttribute.value == attribute.value || attribute.value == true);
  }

  void _format(quill.Attribute attribute) {
    widget.controller.formatSelection(
      richTextFormatAttributeForToggle(widget.controller, attribute),
    );
    widget.focusNode.requestFocus();
  }
}
