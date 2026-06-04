import 'dart:convert';

const richTextContentFormatQuillDeltaJson = 'quill_delta_json';

String emptyRichTextDeltaJson() {
  return jsonEncode([
    {'insert': '\n'},
  ]);
}

String plainTextToRichTextDeltaJson(String text) {
  final normalized = text.trimRight();
  if (normalized.isEmpty) return emptyRichTextDeltaJson();
  return jsonEncode([
    {'insert': '$normalized\n'},
  ]);
}

String richTextDeltaJsonFromPayload({
  required Map<String, dynamic> payload,
  required String deltaKey,
  required String legacyTextKey,
}) {
  final deltaJson = payload[deltaKey] as String?;
  if (deltaJson != null && deltaJson.trim().isNotEmpty) return deltaJson;
  return plainTextToRichTextDeltaJson(payload[legacyTextKey] as String? ?? '');
}

bool richTextDeltaJsonIsBlank(String deltaJson) {
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is! List) return true;
    final text = decoded
        .whereType<Map>()
        .map((operation) => operation['insert'])
        .whereType<String>()
        .join();
    return text.trim().isEmpty;
  } on FormatException {
    return true;
  }
}

String plainTextFromRichTextDeltaJson(String deltaJson) {
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is! List) return '';
    return decoded
        .whereType<Map>()
        .map((operation) => operation['insert'])
        .whereType<String>()
        .join()
        .trimRight();
  } on FormatException {
    return '';
  }
}
