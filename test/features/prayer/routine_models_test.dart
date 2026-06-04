import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/models/app_models.dart';

void main() {
  test('routine section types parse known values and default safely', () {
    expect(
      routineSectionTypeFromString('custom_text'),
      RoutineSectionType.customText,
    );
    expect(
      routineSectionTypeFromString('request_feed'),
      RoutineSectionType.requestFeed,
    );
    expect(
      routineSectionTypeFromString('unknown'),
      RoutineSectionType.customText,
    );
  });

  test('routine sections sort by sort order', () {
    final sections = [
      RoutineSection(
        id: 'section-2',
        sessionId: 'session-1',
        userId: 'user-1',
        type: RoutineSectionType.requestFeed,
        sortOrder: 2000,
        status: 'active',
        title: 'Requests',
        contentDeltaJson: emptyRoutineDeltaJson(),
      ),
      RoutineSection(
        id: 'section-1',
        sessionId: 'session-1',
        userId: 'user-1',
        type: RoutineSectionType.customText,
        sortOrder: 1000,
        status: 'active',
        title: 'Opening',
        contentDeltaJson: plainTextToRoutineDeltaJson('Lord, open our lips.'),
      ),
    ];

    expect(sortedRoutineSections(sections).map((section) => section.id), [
      'section-1',
      'section-2',
    ]);
  });

  test(
    'routine encrypted document metadata contains no plaintext routine text',
    () {
      final metadata = privateRoutineDocumentMetadata(
        userId: 'user-1',
        status: 'active',
        sortOrder: 1000,
        ciphertext: 'ciphertext-base64',
        nonce: 'nonce-base64',
      );

      final encoded = jsonEncode(metadata);

      expect(encoded, isNot(contains('Morning Prayer')));
      expect(encoded, isNot(contains('Lord, open our lips')));
      expect(
        metadata.keys,
        containsAll(['ciphertext', 'nonce', 'payloadVersion']),
      );
    },
  );

  test('routine delta helpers create valid newline-terminated quill json', () {
    expect(jsonDecode(emptyRoutineDeltaJson()), [
      {'insert': '\n'},
    ]);
    expect(jsonDecode(plainTextToRoutineDeltaJson('Lord, open our lips.')), [
      {'insert': 'Lord, open our lips.\n'},
    ]);
  });

  test('legacy routine text converts to quill delta json', () {
    final delta = routineSectionContentDeltaJsonFromPayload({
      'text': '**Bold** *italic*',
    });

    expect(jsonDecode(delta), [
      {'insert': '**Bold** *italic*\n'},
    ]);
  });

  test(
    'request body payload keeps encrypted plaintext fallback and rich text',
    () {
      final delta = plainTextToRichTextDeltaJson('Private request body');
      final payload = requestContentPayload(
        title: 'Please pray',
        body: 'Private request body',
        bodyDeltaJson: delta,
      );

      expect(payload['title'], 'Please pray');
      expect(payload['body'], 'Private request body');
      expect(payload['bodyFormat'], richTextContentFormatQuillDeltaJson);
      expect(payload['bodyDeltaJson'], delta);
    },
  );

  test('legacy request body converts to quill delta json', () {
    final delta = requestBodyDeltaJsonFromPayload({
      'body': 'Private request body',
    });

    expect(jsonDecode(delta), [
      {'insert': 'Private request body\n'},
    ]);
  });
}
