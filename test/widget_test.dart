import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vesper/app.dart';
import 'package:vesper/core/crypto/encryption_service.dart';
import 'package:vesper/core/crypto/group_key_service.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/app_providers.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/core/theme/theme_preference.dart';
import 'package:vesper/core/widgets/manuscript_widgets.dart';
import 'package:vesper/features/auth/data/auth_repository.dart';
import 'package:vesper/features/groups/data/group_repository.dart';
import 'package:vesper/features/prayer/data/prayer_session_repository.dart';
import 'package:vesper/features/requests/data/prayer_request_repository.dart';
import 'package:vesper/features/profile/data/user_profile_repository.dart';
import 'package:vesper/shared/rich_text/rich_text_widgets.dart';

class _FakeUserProfileRepository implements UserProfileRepository {
  const _FakeUserProfileRepository(this.names);

  final Map<String, String> names;

  @override
  Future<Map<String, String>> displayNamesFor(Iterable<String> userIds) async {
    return Map.fromEntries(
      userIds.where(names.containsKey).map((id) => MapEntry(id, names[id]!)),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository();

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {}

  @override
  Future<void> ensureProfile({String? displayName}) async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeGroupRepository implements GroupRepository {
  const _FakeGroupRepository(
    this.groups, {
    this.watchMyGroupsError,
    this.watchMyGroupsStream,
  });

  final List<VesperGroup> groups;
  final Object? watchMyGroupsError;
  final Stream<List<VesperGroup>>? watchMyGroupsStream;

  @override
  Stream<List<VesperGroup>> watchMyGroups() {
    final stream = watchMyGroupsStream;
    if (stream != null) return stream;
    final error = watchMyGroupsError;
    if (error != null) return Stream.error(error);
    return Stream.value(groups);
  }

  @override
  Stream<int> watchRequestCount(String groupId) => Stream.value(0);

  @override
  Stream<GroupMembership?> watchMyMembership(String groupId) => Stream.value(
    GroupMembership(
      id: '${groupId}_user-1',
      groupId: groupId,
      userId: 'user-1',
      role: 'member',
      status: 'active',
    ),
  );

  @override
  Stream<List<GroupMembership>> watchMembers(String groupId) =>
      Stream.value(const []);

  @override
  Stream<List<JoinRequest>> watchJoinRequests(String groupId) =>
      Stream.value(const []);

  @override
  Future<VesperGroup?> getGroup(String groupId) async => groups
      .where((group) => group.id == groupId)
      .cast<VesperGroup?>()
      .firstOrNull;

  @override
  Future<void> createGroup({
    required String name,
    required String description,
  }) async {}

  @override
  Future<CreatedInviteCode> createInviteCode(String groupId) async =>
      CreatedInviteCode(code: 'VESPER-ABC234', expiresAt: DateTime.utc(2026));

  @override
  Future<void> requestToJoin(String code) async {}

  @override
  Future<void> approveJoinRequest(JoinRequest request) async {}

  @override
  Future<void> rejectJoinRequest(JoinRequest request) async {}

  @override
  Future<void> proposeLeaderAddition(
    String groupId,
    String targetUserId,
  ) async {}

  @override
  Future<void> proposeMemberRemoval(
    String groupId,
    String targetUserId,
  ) async {}

  @override
  Future<void> approveSettingsChange(String changeId) async {}

  @override
  Future<void> disputeSettingsChange(String changeId) async {}

  @override
  Future<void> maybeFinalizeSettingsChanges(String groupId) async {}

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSettingsChanges(
    String groupId,
  ) => const Stream.empty();

  @override
  Future<List<int>> loadGroupKey(String groupId, int keyVersion) async =>
      const [];
}

class _FakePrayerRequestRepository implements PrayerRequestRepository {
  const _FakePrayerRequestRepository({
    this.requests = const [],
    this.watchRequestsError,
    this.watchMyRequestsError,
    this.watchRequestsStream,
    this.watchMyRequestsStream,
    this.privateCreatedTitles,
    this.reportedGroupIds,
  });

  final List<PrayerRequestSummary> requests;
  final Object? watchRequestsError;
  final Object? watchMyRequestsError;
  final Stream<List<PrayerRequestSummary>>? watchRequestsStream;
  final Stream<List<PrayerRequestSummary>>? watchMyRequestsStream;
  final List<String>? privateCreatedTitles;
  final List<String>? reportedGroupIds;

  @override
  Stream<List<PrayerRequestSummary>> watchRequests(VesperGroup group) {
    final stream = watchRequestsStream;
    if (stream != null) return stream;
    final error = watchRequestsError;
    if (error != null) return Stream.error(error);
    return Stream.value(
      requests.where((request) => request.groupId == group.id).toList(),
    );
  }

  @override
  Future<List<PrayerRequestSummary>> readCachedRequests(
    VesperGroup group,
  ) async => requests.where((request) => request.groupId == group.id).toList();

  @override
  Future<void> createRequest({
    required VesperGroup group,
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {}

  @override
  Future<void> createPrivateRequest({
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {
    privateCreatedTitles?.add(title);
  }

  @override
  Future<void> createRequestForGroups({
    required List<VesperGroup> groups,
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {}

  @override
  Future<void> backfillRequestGrantsForMember({
    required VesperGroup group,
    required String memberUserId,
  }) async {}

  @override
  Stream<List<PrayerRequestSummary>> watchMyRequests() {
    final stream = watchMyRequestsStream;
    if (stream != null) return stream;
    final error = watchMyRequestsError;
    if (error != null) return Stream.error(error);
    return Stream.value(requests);
  }

  @override
  Future<void> updateRequest({
    required VesperGroup group,
    required PrayerRequestSummary request,
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {}

  @override
  Future<void> setStatus(String requestId, String status) async {}

  @override
  Future<void> removeRequest(String requestId) async {}

  @override
  Future<void> markPrayed(String groupId, String requestId) async {}

  @override
  Stream<Map<String, PrayerActivity>> watchPrayerActivity(String groupId) =>
      Stream.value(const {});

  @override
  Stream<Map<String, PrayerActivity>> watchPrayerActivityForRequests(
    Iterable<String> requestIds,
  ) => Stream.value(const {});

  @override
  Stream<Map<String, PrayerActivity>> watchLegacyPrayerActivity(
    String groupId,
  ) => Stream.value(const {});

  @override
  Future<void> reportRequest(String groupId, String requestId) async {
    reportedGroupIds?.add(groupId);
  }

  @override
  Future<void> reportRequestForGroups(
    Iterable<VesperGroup> groups,
    String requestId,
  ) async {
    reportedGroupIds?.addAll(groups.map((group) => group.id));
  }

  @override
  Stream<List<RequestReport>> watchRequestReports(String groupId) =>
      Stream.value(const []);

  @override
  Future<void> dismissRequestReport(String reportId) async {}

  @override
  Future<void> removeReportedRequest(RequestReport report) async {}

  @override
  Future<void> setFollowUpReminder(
    String requestId,
    DateTime reminderAt,
  ) async {}
}

class _FakePrayerSessionRepository implements PrayerSessionRepository {
  const _FakePrayerSessionRepository({
    this.sessions = const [],
    this.sections = const [],
    this.createdNames,
    this.createError,
    this.updatedSections,
    this.removedSectionIds,
    this.archivedSessionIds,
    this.addedSectionTypes,
  });

  final List<PrayerSession> sessions;
  final List<RoutineSection> sections;
  final List<String>? createdNames;
  final Object? createError;
  final List<RoutineSection>? updatedSections;
  final List<String>? removedSectionIds;
  final List<String>? archivedSessionIds;
  final List<RoutineSectionType>? addedSectionTypes;

  @override
  Stream<List<PrayerSession>> watchSessions() => Stream.value(sessions);

  @override
  Stream<List<RoutineSection>> watchSections(String sessionId) => Stream.value(
    sections.where((section) => section.sessionId == sessionId).toList(),
  );

  @override
  Future<PrayerSession> createSession(String name) async {
    final error = createError;
    if (error != null) throw error;
    createdNames?.add(name.trim());
    return PrayerSession(
      id: 'created-session',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: name.trim(),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<void> updateSessionName(PrayerSession session, String name) async {}

  @override
  Future<void> archiveSession(String sessionId) async {
    archivedSessionIds?.add(sessionId);
  }

  @override
  Future<void> addSection({
    required String sessionId,
    required RoutineSectionType type,
    required String title,
    required String contentDeltaJson,
  }) async {
    addedSectionTypes?.add(type);
  }

  @override
  Future<void> updateSection(RoutineSection section) async {
    updatedSections?.add(section);
  }

  @override
  Future<void> removeSection(String sectionId) async {
    removedSectionIds?.add(sectionId);
  }
}

bool _pngHasAlpha(Uint8List bytes) {
  const pngSignatureLength = 8;
  const chunkLengthSize = 4;
  const chunkTypeSize = 4;
  const ihdrColorTypeOffset = 9;

  final ihdrStart = pngSignatureLength + chunkLengthSize + chunkTypeSize;
  final colorType = bytes[ihdrStart + ihdrColorTypeOffset];

  return colorType == 4 || colorType == 6;
}

Uint8List _embeddedSvgPng(String svg) {
  final match = RegExp(
    r'href="data:image/png;base64,([^\"]+)"',
  ).firstMatch(svg);

  if (match == null) {
    throw StateError('No embedded PNG found in title graphic SVG.');
  }

  return base64Decode(match.group(1)!);
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const testGroups = [
    VesperGroup(
      id: 'group-1',
      name: 'Morning Group',
      description: '',
      createdBy: 'leader-1',
      activeKeyVersion: 1,
    ),
    VesperGroup(
      id: 'group-2',
      name: 'Evening Group',
      description: '',
      createdBy: 'leader-1',
      activeKeyVersion: 1,
    ),
  ];

  PrayerRequestSummary requestSummary({
    required String id,
    required String groupId,
    required String title,
    String createdBy = 'user-2',
  }) {
    return PrayerRequestSummary(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      status: 'active',
      createdAt: DateTime.utc(2026, 5, 18),
      title: title,
      body: 'Private request body',
    );
  }

  test('title graphic assets include alpha transparency', () {
    final pngBytes = File('assets/title-graphic.png').readAsBytesSync();
    final svg = File('assets/title-graphic.svg').readAsStringSync();

    expect(_pngHasAlpha(pngBytes), isTrue);
    expect(_pngHasAlpha(_embeddedSvgPng(svg)), isTrue);
  });

  test('app theme uses manuscript palette and serif typography', () {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, const Color(0xfffbf3df));
    expect(theme.colorScheme.surface, const Color(0xfffffaf0));
    expect(theme.colorScheme.primary, const Color(0xff208070));
    expect(theme.colorScheme.tertiary, const Color(0xff583070));
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Georgia');
    expect(theme.dividerColor, const Color(0xffdfcfab));
  });

  testWidgets(
    'home lands on Pray with centered request action and Groups tab',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(
              const _FakeGroupRepository(testGroups),
            ),
            authRepositoryProvider.overrideWithValue(
              const _FakeAuthRepository(),
            ),
            prayerRequestRepositoryProvider.overrideWithValue(
              _FakePrayerRequestRepository(
                requests: [
                  PrayerRequestSummary(
                    id: 'request-1',
                    groupId: 'group-1',
                    createdBy: 'user-2',
                    status: 'active',
                    createdAt: DateTime.utc(2026, 5, 18),
                    title: 'Pray for wisdom',
                    body: 'Private request body',
                  ),
                ],
              ),
            ),
            userProfileRepositoryProvider.overrideWithValue(
              const _FakeUserProfileRepository({'user-2': 'Sarah Chen'}),
            ),
            prayerSessionRepositoryProvider.overrideWithValue(
              const _FakePrayerSessionRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pray'), findsWidgets);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.byTooltip('Submit prayer request'), findsOneWidget);
      expect(find.text('Create Routine'), findsOneWidget);
      expect(find.text('Your routines'), findsOneWidget);
      expect(find.text('Prayer requests'), findsOneWidget);
      expect(find.text('Pray for wisdom'), findsOneWidget);
      expect(find.text('Your groups'), findsNothing);

      await tester.tap(find.text('Groups'));
      await tester.pumpAndSettle();

      expect(find.text('Your groups'), findsOneWidget);
      expect(find.text('Morning Group'), findsOneWidget);
    },
  );

  testWidgets('consolidated request feed dedupes requests by id', (
    tester,
  ) async {
    final reportedGroupIds = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            _FakePrayerRequestRepository(
              requests: [
                requestSummary(
                  id: 'request-1',
                  groupId: 'group-1',
                  title: 'Shared request',
                ),
                requestSummary(
                  id: 'request-1',
                  groupId: 'group-2',
                  title: 'Shared request',
                ),
              ],
              reportedGroupIds: reportedGroupIds,
            ),
          ),
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-2': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: ConsolidatedRequestFeed(groups: testGroups)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shared request'), findsOneWidget);
    expect(find.text('MORNING GROUP · EVENING GROUP'), findsOneWidget);

    final menu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    menu.onSelected?.call('report');
    await tester.pumpAndSettle();

    expect(reportedGroupIds, ['group-1', 'group-2']);
  });

  testWidgets(
    'ConsolidatedRequestFeed shows loading before first request response',
    (tester) async {
      final controller = StreamController<List<PrayerRequestSummary>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              const _FakeAuthRepository(),
            ),
            prayerRequestRepositoryProvider.overrideWithValue(
              _FakePrayerRequestRepository(
                watchRequestsStream: controller.stream,
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ConsolidatedRequestFeed(groups: [testGroups.first]),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No requests yet.'), findsNothing);

      controller.add(const []);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No requests yet.'), findsOneWidget);
    },
  );

  test('request report ids are scoped by request group and reporter', () {
    expect(
      requestReportId(
        requestId: 'request-1',
        groupId: 'group-1',
        userId: 'user-2',
      ),
      'request-1_group-1_user-2',
    );
  });

  testWidgets('manuscript card provides a material surface for list tiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManuscriptCard(
            child: ListTile(title: const Text('Quiet group'), onTap: () {}),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('manuscript card borders use routine section border color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ManuscriptCard(innerBorder: true, child: Text('Quiet card')),
        ),
      ),
    );

    final expectedBorderColor = AppTheme.light.colorScheme.secondary.withValues(
      alpha: 0.45,
    );
    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .toList();

    expect(decorations[0].border?.top.color, expectedBorderColor);
    expect(decorations[1].border?.top.color, expectedBorderColor);
  });

  testWidgets('rubric text adds background for low contrast accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightForPreference(
          const ThemePreference.custom(Colors.white),
        ),
        home: const Scaffold(body: RubricText('Low contrast')),
      ),
    );

    expect(find.text('LOW CONTRAST'), findsOneWidget);
    expect(
      find.byKey(const Key('rubric-text-readable-background')),
      findsOneWidget,
    );
  });

  testWidgets('rubric text skips background for readable accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: RubricText('Readable')),
      ),
    );

    expect(find.text('READABLE'), findsOneWidget);
    expect(
      find.byKey(const Key('rubric-text-readable-background')),
      findsNothing,
    );
  });

  testWidgets('groups tab separates group cards vertically', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupCardListItem), findsNWidgets(2));

    final spacedItem = find.descendant(
      of: find.byType(GroupCardListItem).first,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(bottom: 12),
      ),
    );

    expect(spacedItem, findsOneWidget);

    final groupCard = tester.widget<ManuscriptCard>(
      find.descendant(
        of: find.byType(GroupCardListItem).first,
        matching: find.byType(ManuscriptCard),
      ),
    );

    expect(groupCard.innerBorder, isTrue);
  });

  testWidgets(
    'center request action opens multi-group composer with select all',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(
              const _FakeGroupRepository(testGroups),
            ),
            authRepositoryProvider.overrideWithValue(
              const _FakeAuthRepository(),
            ),
            prayerRequestRepositoryProvider.overrideWithValue(
              const _FakePrayerRequestRepository(),
            ),
            prayerSessionRepositoryProvider.overrideWithValue(
              const _FakePrayerSessionRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Submit prayer request'));
      await tester.pumpAndSettle();

      expect(find.text('Share a Prayer Request'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Title'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      expect(find.byType(RichTextContentEditor), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Request Prayer'), findsNothing);
      expect(find.text('Choose groups'), findsNothing);
      expect(find.text('Select All'), findsNothing);
      expect(find.text('Morning Group'), findsNothing);
      expect(find.text('Evening Group'), findsNothing);
      expect(find.text('0 groups selected'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Choose groups'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Morning Group'), findsOneWidget);
      expect(find.text('Evening Group'), findsOneWidget);
      expect(find.text('0 groups selected'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Request Prayer'), findsOneWidget);

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(find.text('2 groups selected'), findsOneWidget);
    },
  );

  testWidgets('multi-group composer back preserves selected groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Submit prayer request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning Group'));
    await tester.pumpAndSettle();

    expect(find.text('1 group selected'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Share a Prayer Request'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Title'), findsOneWidget);
    expect(find.text('Choose groups'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('1 group selected'), findsOneWidget);
  });

  testWidgets('Groups tab owns group creation and join entry point', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();

    expect(find.text('Create or join group'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Create or join group'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Create or join group'));
    await tester.pumpAndSettle();

    expect(find.text('Create a Group'), findsOneWidget);
    expect(find.text('Request to join'), findsOneWidget);
  });

  testWidgets('Create Routine opens routine creation form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Routine'));
    await tester.pumpAndSettle();

    expect(find.text('Create a routine'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Routine name'), findsOneWidget);
  });

  testWidgets('Create Routine submits name and opens routine reader', (
    tester,
  ) async {
    final createdNames = <String>[];
    final addedTypes = <RoutineSectionType>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              createdNames: createdNames,
              addedSectionTypes: addedTypes,
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Routine'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Routine name'),
      'Midday Prayer',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Routine'));
    await tester.pumpAndSettle();

    expect(createdNames, ['Midday Prayer']);
    expect(addedTypes, [RoutineSectionType.requestFeed]);
    expect(find.text('Create a routine'), findsNothing);
    expect(find.text('Midday Prayer'), findsOneWidget);
    expect(find.text('Add a section to begin this routine.'), findsOneWidget);
  });

  testWidgets('Create Routine shows inline error when name is blank', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Routine'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Name this routine first.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Create a routine'), findsOneWidget);
  });

  testWidgets('Create Routine shows inline error when save fails', (
    tester,
  ) async {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              createError: FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
                message: 'Missing or insufficient permissions.',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Routine'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Routine name'),
      'Midday Prayer',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Routine'));
    await tester.pumpAndSettle();
    debugPrint = previousDebugPrint;

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('This routine could not be created.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Create a routine'), findsOneWidget);
    expect(
      messages,
      contains(
        'Routine creation error: FirebaseException code=permission-denied message=Missing or insufficient permissions.',
      ),
    );
  });

  testWidgets('Pray tab shows group load errors instead of empty feed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            _FakeGroupRepository(
              const [],
              watchMyGroupsError: StateError('missing index'),
            ),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We could not load your groups.'), findsOneWidget);
    expect(
      find.text('Requests from your groups will appear here.'),
      findsNothing,
    );
  });

  testWidgets('Pray tab shows request load errors instead of empty requests', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            _FakePrayerRequestRepository(
              watchRequestsError: StateError('cannot decrypt'),
            ),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We could not load requests.'), findsOneWidget);
    expect(find.text('No requests yet.'), findsNothing);
  });

  testWidgets('RequestList shows loading before first group request response', (
    tester,
  ) async {
    final controller = StreamController<List<PrayerRequestSummary>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            _FakePrayerRequestRepository(watchRequestsStream: controller.stream),
          ),
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestList(group: testGroups.first, isLeader: false),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No requests yet.'), findsNothing);

    controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No requests yet.'), findsOneWidget);
  });

  testWidgets('routine row opens selected routine reader', (tester) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.customText,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Opening',
                  contentDeltaJson: '[{"insert":"Lord, open our lips.\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Prayer'));
    await tester.pumpAndSettle();

    expect(find.text('Opening'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Lord, open our lips.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Step 1 of 1'), findsOneWidget);
  });

  testWidgets('request feed routine step preserves join in prayer action', (
    tester,
  ) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-2': 'Sarah Chen'}),
          ),
          prayerRequestRepositoryProvider.overrideWithValue(
            _FakePrayerRequestRepository(
              requests: [
                PrayerRequestSummary(
                  id: 'request-1',
                  groupId: 'group-1',
                  createdBy: 'user-2',
                  status: 'active',
                  createdAt: DateTime.utc(2026, 5, 18),
                  title: 'Pray for wisdom',
                  body: 'Private request body',
                ),
              ],
            ),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.requestFeed,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Prayer requests',
                  contentDeltaJson: '[{"insert":"\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Prayer'));
    await tester.pumpAndSettle();

    expect(find.text('Prayer requests'), findsOneWidget);
    expect(find.text('Pray for wisdom'), findsOneWidget);
    expect(find.text('Join in prayer'), findsOneWidget);
  });

  testWidgets('routine section content renders quill delta in a card', (
    tester,
  ) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.customText,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Opening',
                  contentDeltaJson:
                      '[{"insert":"Bold","attributes":{"bold":true}},{"insert":" italic","attributes":{"italic":true}},{"insert":" struck","attributes":{"strike":true}},{"insert":"\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: RoutineReaderScreen(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opening'), findsOneWidget);
    expect(find.byType(RoutineSectionContentCard), findsOneWidget);
    expect(find.text('Prayer text'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(RoutineSectionContentCard),
        matching: find.text('Opening'),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Bold italic struck'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Routine request section shows loading before groups response', (
    tester,
  ) async {
    final controller = StreamController<List<VesperGroup>>();
    addTearDown(controller.close);

    const section = RoutineSection(
      id: 'section-requests',
      sessionId: 'session-1',
      userId: 'user-1',
      type: RoutineSectionType.requestFeed,
      sortOrder: 1000,
      status: 'active',
      title: 'Prayer requests',
      contentDeltaJson: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            _FakeGroupRepository(
              const [],
              watchMyGroupsStream: controller.stream,
            ),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RoutineSectionBody(section: section)),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No requests are ready here yet.'), findsNothing);

    controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No requests are ready here yet.'), findsOneWidget);
  });

  test('routine format buttons return unset attributes when active', () {
    final controller = routineQuillControllerFromDeltaJson(
      plainTextToRoutineDeltaJson('Amen'),
    );

    controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 4),
      quill.ChangeSource.local,
    );

    final firstToggle = routineFormatAttributeForToggle(
      controller,
      quill.Attribute.bold,
    );
    controller.formatSelection(firstToggle);

    final secondToggle = routineFormatAttributeForToggle(
      controller,
      quill.Attribute.bold,
    );

    expect(firstToggle, quill.Attribute.bold);
    expect(secondToggle.key, quill.Attribute.bold.key);
    expect(secondToggle.value, isNull);
  });

  testWidgets('rich text toolbar marks active formats as selected', (
    tester,
  ) async {
    final controller = richTextControllerFromDeltaJson(
      '[{"insert":"Bold","attributes":{"bold":true}},{"insert":" plain\\n"}]',
    );
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RichTextFormatToolbar(
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      ),
    );

    controller.updateSelection(
      const TextSelection.collapsed(offset: 1),
      quill.ChangeSource.local,
    );
    await tester.pump();

    final boldButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.format_bold),
    );
    final italicButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.format_italic),
    );

    expect(boldButton.isSelected, isTrue);
    expect(italicButton.isSelected, isFalse);
  });

  test('legacy heading routine sections read as prayer sections', () {
    expect(
      routineSectionTypeFromString('heading'),
      RoutineSectionType.customText,
    );
  });

  testWidgets('routine editor opens section edit screen from section rows', (
    tester,
  ) async {
    final removedSectionIds = <String>[];
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              removedSectionIds: removedSectionIds,
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.customText,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Opening',
                  contentDeltaJson: '[{"insert":"Lord, open our lips.\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit routine'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineEditScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Routine name'), findsOneWidget);
    expect(find.text('Save routine name'), findsOneWidget);
    expect(find.byTooltip('Add section'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('custom_text'), findsNothing);
    expect(find.widgetWithText(TextField, 'Section title'), findsNothing);
    expect(find.byTooltip('Edit Opening'), findsOneWidget);

    final sectionCard = tester.widget<ManuscriptCard>(
      find.ancestor(
        of: find.text('Opening'),
        matching: find.byType(ManuscriptCard),
      ),
    );
    final sectionSpacing = find.ancestor(
      of: find.text('Opening'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.only(bottom: 12),
      ),
    );

    expect(sectionCard.innerBorder, isTrue);
    expect(sectionSpacing, findsOneWidget);

    await tester.tap(find.byTooltip('Edit Opening'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Section'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Section title'), findsOneWidget);
    expect(find.byTooltip('Remove Opening'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineEditScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Section title'), findsNothing);

    await tester.tap(find.byTooltip('Edit Opening'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove Opening'));
    await tester.pumpAndSettle();

    expect(removedSectionIds, ['section-1']);
    expect(find.byType(RoutineEditScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineEditScreen), findsNothing);
    expect(find.byType(RoutineReaderScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Lord, open our lips.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('routine section edit screen actions work with app theme', (
    tester,
  ) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.customText,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Opening',
                  contentDeltaJson: '[{"insert":"Lord, open our lips.\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: RoutineReaderScreen(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Opening'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Section'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Section title'), findsOneWidget);
    expect(find.text('Save section'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('routine editor updates drag reorders and archives sections', (
    tester,
  ) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final updatedSections = <RoutineSection>[];
    final archivedSessionIds = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              updatedSections: updatedSections,
              archivedSessionIds: archivedSessionIds,
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.customText,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Opening',
                  contentDeltaJson: '[{"insert":"Lord, open our lips.\\n"}]',
                ),
                RoutineSection(
                  id: 'section-2',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.customText,
                  sortOrder: 2000,
                  status: 'active',
                  title: 'Closing',
                  contentDeltaJson: '[{"insert":"Amen.\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit routine'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Opening'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Section title'),
      'Opening prayer',
    );
    expect(find.widgetWithText(TextField, 'Section text'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Lord, open our lips.'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Save section'));
    await tester.tap(find.text('Save section'));
    await tester.pumpAndSettle();

    expect(updatedSections.single.title, 'Opening prayer');
    expect(
      updatedSections.single.contentDeltaJson,
      '[{"insert":"Lord, open our lips.\\n"}]',
    );
    expect(find.byType(RoutineEditScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Section title'), findsNothing);

    final openingDragHandle = find.byIcon(Icons.drag_handle).first;
    await tester.ensureVisible(openingDragHandle);
    await tester.timedDrag(
      openingDragHandle,
      const Offset(0, 320),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(updatedSections.length, 3);
    expect(updatedSections[1].id, 'section-2');
    expect(updatedSections[1].sortOrder, 1000);
    expect(updatedSections[2].id, 'section-1');
    expect(updatedSections[2].sortOrder, 2000);

    await tester.ensureVisible(find.text('Archive routine'));
    await tester.tap(find.text('Archive routine'));
    await tester.pumpAndSettle();

    expect(archivedSessionIds, ['session-1']);
  });

  testWidgets('routine editor add sheet offers section and request feed only', (
    tester,
  ) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final addedTypes = <RoutineSectionType>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              addedSectionTypes: addedTypes,
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit routine'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add section'));
    await tester.pumpAndSettle();
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Heading'), findsNothing);
    expect(find.text('Prayer'), findsNothing);
    expect(find.text('Silence'), findsNothing);
    expect(find.text('Reading'), findsNothing);
    expect(find.text('Request Feed'), findsOneWidget);

    await tester.tap(find.text('Section'));
    await tester.pumpAndSettle();

    expect(addedTypes, [RoutineSectionType.customText]);
  });

  testWidgets('routine editor add FAB directly adds section when feed exists', (
    tester,
  ) async {
    final session = PrayerSession(
      id: 'session-1',
      userId: 'user-1',
      status: 'active',
      sortOrder: 1000,
      name: 'Morning Prayer',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final addedTypes = <RoutineSectionType>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            _FakePrayerSessionRepository(
              sessions: [session],
              addedSectionTypes: addedTypes,
              sections: const [
                RoutineSection(
                  id: 'section-1',
                  sessionId: 'session-1',
                  userId: 'user-1',
                  type: RoutineSectionType.requestFeed,
                  sortOrder: 1000,
                  status: 'active',
                  title: 'Prayer requests',
                  contentDeltaJson: '[{"insert":"\\n"}]',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add section'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('add-section-request_feed')),
      findsNothing,
    );
    expect(addedTypes, [RoutineSectionType.customText]);
  });

  test('invite QR payload parser accepts raw and URI invite codes', () {
    expect(inviteCodeFromQrPayload('VESPER-ABC234'), 'VESPER-ABC234');
    expect(
      inviteCodeFromQrPayload('vesper://invite?code=VESPER-ABC234'),
      'VESPER-ABC234',
    );
    expect(inviteCodeFromQrPayload('not an invite'), isNull);
  });

  test('request stream errors are logged for diagnosis', () {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    logRequestStreamError('permission-denied', StackTrace.fromString('trace'));

    expect(messages, contains('Request stream error: permission-denied'));
    expect(messages, contains('Request stream stack: trace'));
  });

  testWidgets('privacy note explains end-to-end encryption calmly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PrivacyNote())),
    );

    expect(find.textContaining('End-to-end encrypted'), findsOneWidget);
    expect(find.textContaining('Vesper cannot read'), findsOneWidget);
  });

  testWidgets('prayer composer uses rich text request body editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PrayerComposerSheet(
              group: VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Request'), findsOneWidget);
    expect(find.byType(RichTextContentEditor), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Request'), findsNothing);
    expect(find.text('Request Prayer'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Select All'), findsNothing);
  });

  testWidgets('prayer composer closes after successful submit', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PrayerComposerSheet(
                  group: const VesperGroup(
                    id: 'group-1',
                    name: 'Group',
                    description: '',
                    createdBy: 'leader-1',
                    activeKeyVersion: 1,
                  ),
                  onCreateRequest:
                      ({
                        required title,
                        required body,
                        required bodyDeltaJson,
                      }) async {
                        submitted = true;
                      },
                ),
              ),
              child: const Text('Open composer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open composer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Title');
    await tester.tap(find.text('Request Prayer'));
    await tester.pumpAndSettle();

    expect(submitted, isTrue);
    expect(find.text('Share a Prayer Request'), findsNothing);
  });

  testWidgets('prayer composer can save a private request without groups', (
    tester,
  ) async {
    final privateTitles = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRequestRepositoryProvider.overrideWithValue(
            _FakePrayerRequestRepository(privateCreatedTitles: privateTitles),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PrayerComposerSheet(groups: [])),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Private');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Prayer'));
    await tester.pumpAndSettle();

    expect(privateTitles, ['Private']);
  });

  testWidgets('invite modal shows QR code text and copy action', (
    tester,
  ) async {
    var copied = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InviteMemberSheet(
            inviteCode: 'VESPER-ABC234',
            expiresAt: DateTime.utc(2026, 5, 24),
            onCopy: () async => copied = true,
          ),
        ),
      ),
    );

    expect(find.text('Invite a New Member'), findsOneWidget);
    expect(find.byKey(const Key('invite-qr-code')), findsOneWidget);
    expect(find.text('VESPER-ABC234'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy invite code'));
    await tester.pumpAndSettle();

    expect(copied, isTrue);
  });

  testWidgets('profile name text shows a display name instead of user id', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileNameText(userId: 'user-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('user-1'), findsNothing);
  });

  testWidgets('request card includes the author display name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Morning Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'someone-else',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.textContaining('user-1'), findsNothing);
    expect(find.text('MORNING GROUP'), findsOneWidget);
    expect(find.text('PRIVATE TO MORNING GROUP'), findsNothing);
  });

  testWidgets('request card group label uses theme accent', (tester) async {
    const customAccent = Color(0xff336699);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightForPreference(
            const ThemePreference.custom(customAccent),
          ),
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Morning Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'someone-else',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final groupLabel = tester.widget<Text>(find.text('MORNING GROUP'));
    expect(groupLabel.style?.color, customAccent);
  });

  testWidgets('request card renders rich text request body', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
                bodyDeltaJson:
                    '[{"insert":"Private","attributes":{"bold":true}},{"insert":" request body\\n"}]',
              ),
              isLeader: false,
              currentUserId: 'someone-else',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RichTextContentViewer), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Private request body'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('request actions are hidden behind top right details menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prayed'), findsNothing);
    expect(find.text('Follow up'), findsNothing);
    expect(find.text('Resolve'), findsNothing);
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Update'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byTooltip('Request actions'));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
  });

  testWidgets('other user request can be double tapped as prayed', (
    tester,
  ) async {
    var prayed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-2',
              onDoubleTapPrayed: () => prayed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prayed'), findsNothing);

    await tester.tap(find.text('Please pray'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Please pray'));
    await tester.pumpAndSettle();

    expect(prayed, isTrue);
  });

  test('new prayer requests publish immediately', () {
    expect(newPrayerRequestStatus(), 'active');
  });

  test('group feed statuses include only active requests', () {
    expect(groupFeedStatuses(), ['active']);
  });

  test('request reports store metadata without plaintext content', () {
    final report = RequestReport(
      id: 'request-1_group-1_user-2',
      groupId: 'group-1',
      requestId: 'request-1',
      reportedBy: 'user-2',
      status: 'open',
      createdAt: DateTime.utc(2026, 5, 19),
    );

    expect(report.status, 'open');
    expect(report.requestId, 'request-1');
  });

  test('joining prayer text follows requester and prayed states', () {
    expect(
      joiningPrayerText(
        prayedCount: 0,
        hasCurrentUserPrayed: false,
        isRequester: true,
      ),
      isNull,
    );
    expect(
      joiningPrayerText(
        prayedCount: 0,
        hasCurrentUserPrayed: false,
        isRequester: false,
      ),
      isNull,
    );
    expect(
      joiningPrayerText(
        prayedCount: 3,
        hasCurrentUserPrayed: false,
        isRequester: true,
      ),
      '3 joining in prayer',
    );
    expect(
      joiningPrayerText(
        prayedCount: 3,
        hasCurrentUserPrayed: true,
        isRequester: false,
      ),
      'You and 2 others joining in prayer',
    );
    expect(
      joiningPrayerText(
        prayedCount: 1,
        hasCurrentUserPrayed: true,
        isRequester: false,
      ),
      'You joining in prayer',
    );
    expect(
      joiningPrayerText(
        prayedCount: 3,
        hasCurrentUserPrayed: false,
        isRequester: false,
      ),
      '3 joining in prayer',
    );
  });

  test('prayer activity aggregates unique prayed actions', () {
    final activity = prayerActivityFromActions(
      currentUserId: 'user-2',
      actions: const [
        PrayerAction(requestId: 'request-1', userId: 'user-2', type: 'prayed'),
        PrayerAction(requestId: 'request-1', userId: 'user-3', type: 'prayed'),
        PrayerAction(requestId: 'request-1', userId: 'user-3', type: 'prayed'),
        PrayerAction(
          requestId: 'request-2',
          userId: 'user-4',
          type: 'reported',
        ),
      ],
    );

    expect(activity['request-1']?.prayedCount, 2);
    expect(activity['request-1']?.hasCurrentUserPrayed, isTrue);
    expect(activity.containsKey('request-2'), isFalse);
  });

  test('request share and grant ids are stable and scoped', () {
    expect(requestShareId('request-1', 'group-1'), 'request-1_group-1');
    expect(requestKeyGrantId('request-1', 'user-1'), 'request-1_user-1');
  });

  test('canonical request firestore data omits plaintext request content', () {
    final data = canonicalPrayerRequestData(
      createdBy: 'user-1',
      payload: const EncryptedPayload(
        ciphertext: 'ciphertext-base64',
        nonce: 'nonce-base64',
        keyVersion: 1,
        payloadVersion: 3,
        algorithm: 'xchacha20-poly1305',
      ),
    );

    expect(data['createdBy'], 'user-1');
    expect(data['status'], 'active');
    expect(data.values.whereType<String>(), isNot(contains('Please pray')));
    expect(
      data.values.whereType<String>(),
      isNot(contains('Private request body')),
    );
    expect(data.keys, isNot(contains('title')));
    expect(data.keys, isNot(contains('body')));
    expect(data.keys, isNot(contains('groupId')));
  });

  test('request share firestore data is metadata only', () {
    final data = requestShareData(
      requestId: 'request-1',
      groupId: 'group-1',
      sharedBy: 'user-1',
    );

    expect(data['requestId'], 'request-1');
    expect(data['groupId'], 'group-1');
    expect(data['status'], 'active');
    expect(
      data.values.whereType<String>(),
      isNot(contains('Private request body')),
    );
    expect(data.keys, isNot(contains('ciphertext')));
  });

  test('request key grant firestore data wraps key metadata only', () {
    final data = requestKeyGrantData(
      requestId: 'request-1',
      userId: 'new-member',
      grantedBy: 'leader-1',
      grantedViaGroupId: 'group-1',
      wrappedKey: const WrappedGroupKey(
        encryptedGroupKey: 'wrapped-key',
        nonce: 'nonce',
        ephemeralPublicKey: 'ephemeral-public-key',
        algorithm: 'x25519-xchacha20-poly1305',
      ),
    );

    expect(data['requestId'], 'request-1');
    expect(data['userId'], 'new-member');
    expect(data['grantedBy'], 'leader-1');
    expect(data['grantedViaGroupId'], 'group-1');
    expect(data['encryptedGroupKey'], 'wrapped-key');
    expect(data.keys, isNot(contains('title')));
    expect(data.keys, isNot(contains('body')));
  });

  test('request key loading queries grants by request and user', () {
    final repositorySource = File(
      'lib/features/requests/data/prayer_request_repository.dart',
    ).readAsStringSync();

    expect(repositorySource, contains(".collection('request_key_grants')"));
    expect(
      repositorySource,
      contains(".where('requestId', isEqualTo: requestId)"),
    );
    expect(repositorySource, contains(".where('userId', isEqualTo: _uid)"));
    expect(repositorySource, contains('.limit(1)'));
    expect(
      repositorySource,
      isNot(contains('.doc(requestKeyGrantId(requestId, _uid))')),
    );
  });

  test('firestore rules validate batched request share creation post-commit', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(
      rules,
      contains(
        r'existsAfter(/databases/$(database)/documents/prayer_requests/$(request.resource.data.requestId))',
      ),
    );
    expect(
      rules,
      contains(
        r'getAfter(/databases/$(database)/documents/prayer_requests/$(request.resource.data.requestId)).data.createdBy == request.auth.uid',
      ),
    );
    expect(
      rules,
      contains(
        'existsAfter(requestSharePath(request.resource.data.requestId, request.resource.data.grantedViaGroupId))',
      ),
    );
    expect(
      rules,
      contains(
        "getAfter(requestSharePath(request.resource.data.requestId, request.resource.data.grantedViaGroupId)).data.status == 'active'",
      ),
    );
  });

  testWidgets('request list shows all requests newest first while scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 260,
              child: ListView(
                children: [
                  RequestCards(
                    group: const VesperGroup(
                      id: 'group-1',
                      name: 'Group',
                      description: '',
                      createdBy: 'leader-1',
                      activeKeyVersion: 1,
                    ),
                    requests: [
                      PrayerRequestSummary(
                        id: 'request-oldest',
                        groupId: 'group-1',
                        createdBy: 'user-1',
                        status: 'active',
                        createdAt: DateTime.utc(2026, 5, 16),
                        title: 'Oldest request',
                        body: 'Private request body',
                      ),
                      PrayerRequestSummary(
                        id: 'request-newest',
                        groupId: 'group-1',
                        createdBy: 'user-1',
                        status: 'active',
                        createdAt: DateTime.utc(2026, 5, 18),
                        title: 'Newest request',
                        body: 'Private request body',
                      ),
                      PrayerRequestSummary(
                        id: 'request-middle',
                        groupId: 'group-1',
                        createdBy: 'user-1',
                        status: 'active',
                        createdAt: DateTime.utc(2026, 5, 17),
                        title: 'Middle request',
                        body: 'Private request body',
                      ),
                    ],
                    isLeader: false,
                    offline: false,
                    currentUserId: 'viewer-1',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Newest request'), findsOneWidget);

    final newestTop = tester.getTopLeft(find.text('Newest request')).dy;
    final middleTop = tester.getTopLeft(find.text('Middle request')).dy;
    final oldestTopBeforeScroll = tester
        .getTopLeft(find.text('Oldest request'))
        .dy;
    expect(newestTop, lessThan(middleTop));
    expect(oldestTopBeforeScroll, greaterThan(260));

    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Oldest request')).dy, lessThan(260));
  });

  testWidgets('request card moves metadata under title and shows join link', (
    tester,
  ) async {
    var joined = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-2',
              prayerActivity: const PrayerActivity(
                prayedCount: 0,
                hasCurrentUserPrayed: false,
              ),
              onJoinPrayer: () => joined = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleTop = tester.getTopLeft(find.text('Please pray')).dy;
    final metadataTop = tester
        .getTopLeft(find.textContaining('Sarah Chen · active'))
        .dy;
    final bodyTop = tester
        .getTopLeft(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Private request body'),
          ),
        )
        .dy;
    expect(titleTop, lessThan(metadataTop));
    expect(metadataTop, lessThan(bodyTop));
    expect(find.textContaining('joining in prayer'), findsNothing);
    expect(find.text('Join in prayer'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Join in prayer'));
    await tester.pumpAndSettle();

    expect(joined, isTrue);
  });

  testWidgets('requester sees no prayer line when count is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-1',
              prayerActivity: const PrayerActivity(
                prayedCount: 0,
                hasCurrentUserPrayed: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('joining in prayer'), findsNothing);
    expect(find.text('Join in prayer'), findsNothing);
  });

  testWidgets('requester sees prayer count without join link', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-1',
              prayerActivity: const PrayerActivity(
                prayedCount: 2,
                hasCurrentUserPrayed: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 joining in prayer'), findsOneWidget);
    expect(find.text('Join in prayer'), findsNothing);
  });

  testWidgets('prayed user sees you and others prayer text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-2',
              prayerActivity: const PrayerActivity(
                prayedCount: 4,
                hasCurrentUserPrayed: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You and 3 others joining in prayer'), findsOneWidget);
    expect(find.text('Join in prayer'), findsNothing);
  });

  testWidgets('other user request exposes report action in details menu', (
    tester,
  ) async {
    var reported = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: false,
              currentUserId: 'user-2',
              onReportRequest: () => reported = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, 'Report'), findsNothing);

    final menu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    final items = menu.itemBuilder(
      tester.element(find.byType(PopupMenuButton<String>)),
    );

    expect(
      items.map((item) => ((item as PopupMenuItem<String>).child as Text).data),
      contains('Report'),
    );

    menu.onSelected!('report');
    await tester.pumpAndSettle();

    expect(reported, isTrue);
  });

  testWidgets('leaders can remove but not answer other users requests', (
    tester,
  ) async {
    var removed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestCard(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              request: PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
              isLeader: true,
              currentUserId: 'leader-1',
              onRemoveRequest: () => removed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, 'Answered'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Remove'), findsNothing);

    final menu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    final itemLabels = menu
        .itemBuilder(tester.element(find.byType(PopupMenuButton<String>)))
        .map((item) => ((item as PopupMenuItem<String>).child as Text).data);

    expect(itemLabels, isNot(contains('Answered')));
    expect(itemLabels, contains('Remove'));

    menu.onSelected!('remove');
    await tester.pumpAndSettle();

    expect(removed, isTrue);
  });

  testWidgets('join requests render in group settings section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({
              'user-1': 'Sarah Chen',
              'leader-1': 'Alex Rivera',
            }),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: JoinRequestSettingsSection(
              requests: const [
                JoinRequest(
                  id: 'join-1',
                  groupId: 'group-1',
                  requestedBy: 'user-1',
                  invitedBy: 'leader-1',
                  status: 'pending',
                ),
              ],
              onApprove: (_) {},
              onReject: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Join Requests'), findsOneWidget);
    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.textContaining('Alex Rivera'), findsOneWidget);
  });

  testWidgets('reported requests render in group settings section', (
    tester,
  ) async {
    var dismissed = false;
    var removed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-2': 'Jordan Lee'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestReportSettingsSection(
              reports: [
                RequestReport(
                  id: 'request-1_user-2',
                  groupId: 'group-1',
                  requestId: 'request-1',
                  reportedBy: 'user-2',
                  status: 'open',
                  createdAt: DateTime.utc(2026, 5, 19),
                ),
              ],
              onDismiss: (_) => dismissed = true,
              onRemove: (_) => removed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Reported Requests'), findsOneWidget);
    expect(find.textContaining('Jordan Lee'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);

    await tester.tap(find.text('Remove request'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
  });

  testWidgets('non-leader settings content shows only members and invite', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GroupSettingsContent(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              isLeader: false,
              members: const [
                GroupMembership(
                  id: 'group-1_user-1',
                  groupId: 'group-1',
                  userId: 'user-1',
                  role: 'member',
                  status: 'active',
                ),
              ],
              joinRequests: const [
                JoinRequest(
                  id: 'join-1',
                  groupId: 'group-1',
                  requestedBy: 'user-2',
                  invitedBy: null,
                  status: 'pending',
                ),
              ],
              reports: const [],
              pendingChanges: const [],
              onInvite: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Members'), findsOneWidget);
    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.text('Invite a New Member'), findsOneWidget);
    expect(find.text('Join Requests'), findsNothing);
    expect(find.text('Reported Requests'), findsNothing);
    expect(find.text('Pending Changes'), findsNothing);
    expect(find.text('Inviter unknown'), findsNothing);
  });

  testWidgets('leader settings content places join requests in members list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({
              'user-1': 'Sarah Chen',
              'user-2': 'Jordan Lee',
              'leader-1': 'Alex Rivera',
            }),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GroupSettingsContent(
              group: const VesperGroup(
                id: 'group-1',
                name: 'Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
              isLeader: true,
              members: const [
                GroupMembership(
                  id: 'group-1_user-1',
                  groupId: 'group-1',
                  userId: 'user-1',
                  role: 'member',
                  status: 'active',
                ),
              ],
              joinRequests: const [
                JoinRequest(
                  id: 'join-1',
                  groupId: 'group-1',
                  requestedBy: 'user-2',
                  invitedBy: 'leader-1',
                  status: 'pending',
                ),
              ],
              reports: [
                RequestReport(
                  id: 'report-1',
                  groupId: 'group-1',
                  requestId: 'request-1',
                  reportedBy: 'user-2',
                  status: 'open',
                  createdAt: DateTime.utc(2026, 5, 19),
                ),
              ],
              pendingChanges: const [],
              onInvite: () async {},
              onApproveJoinRequest: (_) {},
              onRejectJoinRequest: (_) {},
              onDismissReport: (_) {},
              onRemoveReport: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join Requests'), findsNothing);
    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.textContaining('Jordan Lee'), findsNWidgets(2));
    expect(find.textContaining('Alex Rivera'), findsOneWidget);
    expect(find.text('Invite a New Member'), findsOneWidget);
    expect(find.text('Reported Requests'), findsOneWidget);

    final membersTop = tester.getTopLeft(find.text('Members')).dy;
    final inviteTop = tester.getTopLeft(find.text('Invite a New Member')).dy;
    final reportsTop = tester.getTopLeft(find.text('Reported Requests')).dy;
    expect(membersTop, lessThan(inviteTop));
    expect(inviteTop, lessThan(reportsTop));
  });

  testWidgets('group actions sheet offers invite QR scanning', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: GroupActionsSheet())),
      ),
    );

    expect(find.text('Scan Invite QR Code'), findsOneWidget);
  });

  testWidgets('invite QR scanner submits scanned invite code', (tester) async {
    String? requestedCode;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InviteQrScanner(
            scanner: (onScan) => ElevatedButton(
              onPressed: () => onScan('vesper://invite?code=VESPER-ABC234'),
              child: const Text('Simulate scan'),
            ),
            onRequestJoin: (code) async => requestedCode = code,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Simulate scan'));
    await tester.pumpAndSettle();

    expect(requestedCode, 'VESPER-ABC234');
  });

  testWidgets('pinned groups section shows pinned groups first', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinnedGroupsSection(
            groups: const [
              VesperGroup(
                id: 'group-1',
                name: 'Pinned Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
            ],
            pinnedGroupIds: const {'group-1'},
            builder: (group) => Text(group.name),
          ),
        ),
      ),
    );

    expect(find.text('Pinned Groups'), findsOneWidget);
    expect(find.text('Pinned Group'), findsOneWidget);
  });

  testWidgets('group row long press shows pin share and leave menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupEntryMenu(
            pinLabel: 'Pin',
            onPin: () {},
            onShare: () {},
            onLeave: () {},
            child: const ListTile(title: Text('Evening Group')),
          ),
        ),
      ),
    );

    expect(find.text('Pin'), findsNothing);

    await tester.longPress(find.text('Evening Group'));
    await tester.pumpAndSettle();

    expect(find.text('Pin'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('group row long press shows unpin for pinned groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupEntryMenu(
            pinLabel: 'Unpin',
            onPin: () {},
            onShare: () {},
            onLeave: () {},
            child: const ListTile(title: Text('Evening Group')),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Evening Group'));
    await tester.pumpAndSettle();

    expect(find.text('Unpin'), findsOneWidget);
    expect(find.text('Pin'), findsNothing);
  });

  testWidgets('member row long press shows promote and remove menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberEntryMenu(
            onPromote: () {},
            onRemove: () {},
            child: const ListTile(title: Text('Sarah Chen')),
          ),
        ),
      ),
    );

    expect(find.text('Promote'), findsNothing);

    await tester.longPress(find.text('Sarah Chen'));
    await tester.pumpAndSettle();

    expect(find.text('Promote'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('profile screen edits name and reuses request cards', (
    tester,
  ) async {
    var savedName = '';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            const _FakeUserProfileRepository({'user-1': 'Sarah Chen'}),
          ),
        ],
        child: MaterialApp(
          home: ProfileScreen(
            initialDisplayName: 'Sarah Chen',
            onSaveName: (name) async => savedName = name,
            requestGroups: const {
              'group-1': VesperGroup(
                id: 'group-1',
                name: 'Morning Group',
                description: '',
                createdBy: 'leader-1',
                activeKeyVersion: 1,
              ),
            },
            requests: [
              PrayerRequestSummary(
                id: 'request-1',
                groupId: 'group-1',
                createdBy: 'user-1',
                status: 'active',
                createdAt: DateTime.utc(2026, 5, 18),
                title: 'Please pray',
                body: 'Private request body',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your profile'), findsNothing);
    expect(find.text('Sarah Chen'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Name'), findsNothing);
    expect(find.text('Your Prayer Requests'), findsOneWidget);
    expect(find.text('Please pray'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log Out'), findsOneWidget);
    expect(find.byTooltip('Request actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Sarah C.');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save name'));
    await tester.pumpAndSettle();

    expect(savedName, 'Sarah C.');
    expect(find.widgetWithText(TextField, 'Name'), findsNothing);
    expect(find.text('Sarah C.'), findsOneWidget);

    await tester.tap(find.byTooltip('Request actions'));
    await tester.pumpAndSettle();

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
  });

  testWidgets('profile request feed shows load errors distinctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            _FakePrayerRequestRepository(
              watchMyRequestsError: StateError('missing request grant'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MyPrayerRequestsForUser(userId: 'user-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We could not load your requests.'), findsOneWidget);
    expect(find.text('Your requests will appear here.'), findsNothing);
  });

  testWidgets(
    'MyPrayerRequestsForUser shows loading before first profile request response',
    (tester) async {
      final controller = StreamController<List<PrayerRequestSummary>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              const _FakeAuthRepository(),
            ),
            prayerRequestRepositoryProvider.overrideWithValue(
              _FakePrayerRequestRepository(
                watchMyRequestsStream: controller.stream,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MyPrayerRequestsForUser(userId: 'user-1')),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Your requests will appear here.'), findsNothing);

      controller.add(const []);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Your requests will appear here.'), findsOneWidget);
    },
  );

  test('profile request feed statuses include non-deleted owned requests', () {
    expect(profileRequestStatuses(), [
      'active',
      'answered',
      'resolved',
      'archived',
    ]);
  });

  testWidgets('home floating action button is icon only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(floatingActionButton: HomeGroupFab(onPressed: null)),
      ),
    );

    expect(find.byIcon(Icons.group_add_outlined), findsOneWidget);
    expect(find.text('Group'), findsNothing);
  });

  testWidgets('home group fab uses chosen theme color background', (
    tester,
  ) async {
    const customAccent = Color(0xfffefefe);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightForPreference(
          const ThemePreference.custom(customAccent),
        ),
        home: const Scaffold(
          floatingActionButton: HomeGroupFab(onPressed: null),
        ),
      ),
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.backgroundColor, customAccent);
  });

  testWidgets('home bottom bar changes background for low contrast accent', (
    tester,
  ) async {
    final theme = AppTheme.lightForPreference(
      const ThemePreference.custom(Colors.white),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavigationBar(
            selectedIndex: 0,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Pray'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    final bottomAppBar = tester.widget<BottomAppBar>(find.byType(BottomAppBar));
    final barColor = bottomAppBar.color!;
    expect(barColor, isNot(theme.colorScheme.surface));
    expect(barColor, isNot(theme.colorScheme.onSurface));
    expect(
      _contrastRatio(theme.colorScheme.primary, barColor),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      find.byKey(const Key('home-tab-label-readable-background')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('home-tab-icon-readable-background')),
      findsNothing,
    );
  });

  testWidgets('home bottom bar keeps surface for readable accent', (
    tester,
  ) async {
    final theme = AppTheme.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavigationBar(
            selectedIndex: 0,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final bottomAppBar = tester.widget<BottomAppBar>(find.byType(BottomAppBar));
    expect(bottomAppBar.color, theme.colorScheme.surface);
  });

  testWidgets('home bottom bar shows split top border around center action', (
    tester,
  ) async {
    final theme = AppTheme.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavigationBar(
            selectedIndex: 0,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final leftBorder = tester.widget<DecoratedBox>(
      find.byKey(const Key('home-bottom-nav-top-border-left')),
    );
    final rightBorder = tester.widget<DecoratedBox>(
      find.byKey(const Key('home-bottom-nav-top-border-right')),
    );
    final leftDecoration = leftBorder.decoration as BoxDecoration;
    final rightDecoration = rightBorder.decoration as BoxDecoration;
    final expectedColor = theme.colorScheme.primary;

    expect(leftDecoration.color, expectedColor);
    expect(rightDecoration.color, expectedColor);
    expect(
      tester
          .getSize(find.byKey(const Key('home-bottom-nav-top-border-left')))
          .height,
      2,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('home-bottom-nav-top-border-right')))
          .height,
      2,
    );
    expect(
      find.byKey(const Key('home-bottom-nav-top-border-center')),
      findsNothing,
    );
    final borderGap =
        tester
            .getTopLeft(
              find.byKey(const Key('home-bottom-nav-top-border-right')),
            )
            .dx -
        tester
            .getTopRight(
              find.byKey(const Key('home-bottom-nav-top-border-left')),
            )
            .dx;
    expect(borderGap, 56);
    expect(
      tester
          .getTopRight(find.byKey(const Key('home-bottom-nav-top-border-left')))
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('home-bottom-nav-top-border-right')),
            )
            .dx,
      ),
    );
  });

  testWidgets('group detail floating action button is icon only', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            const _FakeGroupRepository(testGroups),
          ),
          authRepositoryProvider.overrideWithValue(const _FakeAuthRepository()),
          prayerRequestRepositoryProvider.overrideWithValue(
            const _FakePrayerRequestRepository(),
          ),
          prayerSessionRepositoryProvider.overrideWithValue(
            const _FakePrayerSessionRepository(),
          ),
        ],
        child: MaterialApp(home: GroupDetailScreen(group: testGroups.first)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Submit prayer request'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('New Request'), findsNothing);

    await tester.tap(find.byTooltip('Submit prayer request'));
    await tester.pumpAndSettle();

    expect(find.text('Share a Prayer Request'), findsOneWidget);
  });

  testWidgets('home header uses title graphic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(appBar: HomeHeader())),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final screenCenter = tester.getCenter(find.byType(Scaffold)).dx;
    final titleGraphicCenter = tester
        .getCenter(find.byKey(const Key('home-title-graphic')))
        .dx;
    final titleGraphic = tester.widget<Image>(
      find.byKey(const Key('home-title-graphic')),
    );

    expect(find.byKey(const Key('home-title-graphic')), findsOneWidget);
    expect(
      (titleGraphic.image as AssetImage).assetName,
      'assets/title-graphic.png',
    );
    expect(find.text('Vesper'), findsNothing);
    expect(appBar.toolbarHeight, 96);
    expect(titleGraphic.height, 77.76);
    expect(titleGraphicCenter, closeTo(screenCenter, 0.1));
    expect(appBar.centerTitle, isTrue);
    expect(appBar.backgroundColor, Colors.transparent);
    expect(find.byTooltip('App Settings'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);
  });

  testWidgets('home header settings button opens app settings', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(appBar: HomeHeader())),
      ),
    );

    await tester.tap(find.byTooltip('App Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSettingsScreen), findsOneWidget);
    expect(find.text('App Settings'), findsWidgets);
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('app settings shows theme color options', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final theme = AppTheme.lightForDate(DateTime(2026, 12, 25));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: theme, home: const AppSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.byType(ThemeColorListItem), findsNWidgets(13));
    expect(
      find.byKey(const Key('theme-option-liturgical-roman')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('theme-option-liturgical-byzantine')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('theme-option-liturgical-russian')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('theme-option-liturgical-coptic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('theme-option-liturgical-lutheran')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('theme-option-liturgical-anglican')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('theme-option-liturgical')), findsNothing);
    expect(find.byKey(const Key('theme-option-purple')), findsOneWidget);
    expect(find.byKey(const Key('theme-option-gold')), findsOneWidget);
    expect(find.byKey(const Key('theme-option-lapis')), findsOneWidget);
    expect(find.byKey(const Key('theme-option-black')), findsOneWidget);
    expect(find.byKey(const Key('theme-option-red')), findsOneWidget);
    expect(find.byKey(const Key('theme-option-green')), findsOneWidget);
    expect(find.byKey(const Key('theme-option-custom')), findsOneWidget);
    expect(find.text('Liturgical'), findsNothing);
    expect(find.text('Liturgical (Roman)'), findsOneWidget);
    expect(find.text('Liturgical (Byzantine)'), findsOneWidget);
    expect(find.text('Liturgical (Russian)'), findsOneWidget);
    expect(find.text('Liturgical (Coptic)'), findsOneWidget);
    expect(find.text('Liturgical (Lutheran)'), findsOneWidget);
    expect(find.text('Liturgical (Anglican)'), findsOneWidget);
    expect(find.text('Purple'), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsNWidgets(6));
    expect(find.byIcon(Icons.brush_outlined), findsOneWidget);
    expect(find.text('Dynamic'), findsNothing);
    expect(find.text('Advent/Lent'), findsNothing);
    expect(find.text('Christmas/Easter'), findsNothing);
    expect(find.text('Epiphany'), findsNothing);
    expect(find.text('Good Friday'), findsNothing);
    expect(find.text('Pentecost'), findsNothing);
    expect(find.text('Ordinary Time'), findsNothing);
    expect(
      find.byKey(const Key('theme-option-liturgical-anglican-selected')),
      findsOneWidget,
    );

    final liturgicalCircle = tester.widget<DecoratedBox>(
      find.byKey(const Key('theme-option-liturgical-anglican-circle')),
    );
    final liturgicalDecoration = liturgicalCircle.decoration as BoxDecoration;
    expect(liturgicalDecoration.color, AppTheme.light.colorScheme.primary);

    final customCircle = tester.widget<DecoratedBox>(
      find.byKey(const Key('theme-option-custom-circle')),
    );
    final customDecoration = customCircle.decoration as BoxDecoration;
    expect(customDecoration.color, AppTheme.light.colorScheme.primary);
    expect(customDecoration.gradient, isNull);
  });

  testWidgets('app settings fixed color selection updates selected option', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppSettingsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('theme-option-purple')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('theme-option-purple-selected')),
      findsOneWidget,
    );
  });

  testWidgets('theme preview circles do not react to selected theme', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'theme_color_mode': 'fixed',
      'theme_fixed_option_id': 'purple',
    });
    final selectedTheme = AppTheme.lightForPreference(
      const ThemePreference.fixed('purple'),
    );
    final liturgicalColor = AppTheme.light.colorScheme.primary;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: selectedTheme,
          home: const AppSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final liturgicalCircle = tester.widget<DecoratedBox>(
      find.byKey(const Key('theme-option-liturgical-anglican-circle')),
    );
    final liturgicalDecoration = liturgicalCircle.decoration as BoxDecoration;
    expect(liturgicalDecoration.color, liturgicalColor);
    expect(
      liturgicalDecoration.color,
      isNot(selectedTheme.colorScheme.primary),
    );

    final customCircle = tester.widget<DecoratedBox>(
      find.byKey(const Key('theme-option-custom-circle')),
    );
    final customDecoration = customCircle.decoration as BoxDecoration;
    expect(customDecoration.color, liturgicalColor);
    expect(customDecoration.gradient, isNull);
  });

  testWidgets(
    'app settings liturgical rite selection updates selected option',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AppSettingsScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme-option-liturgical-roman')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('theme-option-liturgical-roman-selected')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('theme-option-liturgical-anglican-selected')),
        findsNothing,
      );
    },
  );

  testWidgets('custom theme option previews selected custom color', (
    tester,
  ) async {
    const customColor = Color(0xff114477);
    SharedPreferences.setMockInitialValues({
      'theme_color_mode': 'custom',
      'theme_custom_color': 0xff114477,
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppSettingsScreen())),
    );
    await tester.pumpAndSettle();

    final customCircle = tester.widget<DecoratedBox>(
      find.byKey(const Key('theme-option-custom-circle')),
    );
    final customDecoration = customCircle.decoration as BoxDecoration;

    expect(customDecoration.color, customColor);
    expect(customDecoration.gradient, isNull);
  });

  testWidgets('app settings custom option opens color picker', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppSettingsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('theme-option-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-option-custom')));
    await tester.pumpAndSettle();

    expect(find.text('Custom Color'), findsOneWidget);
    expect(find.text('Choose an accent color for Vesper.'), findsOneWidget);
    expect(find.text('Choose a quiet accent color for Vesper.'), findsNothing);
    expect(find.text('Use color'), findsOneWidget);
  });

  testWidgets(
    'custom color picker warns when color needs adjusted backgrounds',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeColorPickerSheet(initialColor: Colors.white),
            ),
          ),
        ),
      );

      final warning = find.byKey(const Key('custom-color-readability-warning'));

      expect(warning, findsOneWidget);
      expect(
        find.text('Some backgrounds will adjust for readability.'),
        findsOneWidget,
      );
      expect(
        tester.getCenter(warning).dx,
        greaterThan(tester.getCenter(find.text('Use color')).dx),
      );
    },
  );

  testWidgets('custom color picker hides warning while choosing color', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ThemeColorPickerSheet(initialColor: Colors.white),
          ),
        ),
      ),
    );

    final warning = find.byKey(const Key('custom-color-readability-warning'));
    final picker = find.byKey(const Key('custom-color-picker-interaction'));

    expect(warning, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(picker));
    await tester.pump();

    expect(warning, findsNothing);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('custom color picker hides warning for readable color', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ThemeColorPickerSheet(initialColor: Color(0xff336699)),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('custom-color-readability-warning')),
      findsNothing,
    );
    expect(
      find.text('Some backgrounds will adjust for readability.'),
      findsNothing,
    );
  });

  testWidgets('home header keeps title graphic below top safe area', (
    tester,
  ) async {
    const topSafeArea = 59.0;
    final physicalTopSafeArea = topSafeArea * tester.view.devicePixelRatio;

    tester.view.padding = FakeViewPadding(top: physicalTopSafeArea);
    tester.view.viewPadding = FakeViewPadding(top: physicalTopSafeArea);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(appBar: HomeHeader())),
    );

    final titleGraphicTop = tester
        .getTopLeft(find.byKey(const Key('home-title-graphic')))
        .dy;

    expect(titleGraphicTop, greaterThanOrEqualTo(topSafeArea));
  });

  testWidgets('group actions sheet creates immediate-publication groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: GroupActionsSheet())),
      ),
    );

    expect(find.text('Leader approval before publishing'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Create group'), findsOneWidget);
  });
}
