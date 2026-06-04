import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:vesper/app.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/app_providers.dart';
import 'package:vesper/core/theme/app_theme.dart';
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
  const _FakeGroupRepository(this.groups, {this.watchMyGroupsError});

  final List<VesperGroup> groups;
  final Object? watchMyGroupsError;

  @override
  Stream<List<VesperGroup>> watchMyGroups() {
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
  });

  final List<PrayerRequestSummary> requests;
  final Object? watchRequestsError;

  @override
  Stream<List<PrayerRequestSummary>> watchRequests(VesperGroup group) {
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
  Future<void> reportRequest(String groupId, String requestId) async {}

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

    await tester.tap(find.text('Create or join group'));
    await tester.pumpAndSettle();

    expect(find.text('Create a group'), findsOneWidget);
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

    expect(
      find.text('We could not load requests for Morning Group.'),
      findsOneWidget,
    );
    expect(find.text('No requests yet.'), findsNothing);
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

    await tester.tap(find.byTooltip('Edit Opening'));
    await tester.pumpAndSettle();

    expect(find.text('Edit section'), findsOneWidget);
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

    expect(find.text('Edit section'), findsOneWidget);
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
    expect(find.text('Request feed'), findsOneWidget);

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
              currentUserId: 'someone-else',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.textContaining('user-1'), findsNothing);
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
      id: 'request-1_user-2',
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

    expect(find.text('Join requests'), findsOneWidget);
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

    expect(find.text('Reported requests'), findsOneWidget);
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
    expect(find.text('Join requests'), findsNothing);
    expect(find.text('Reported requests'), findsNothing);
    expect(find.text('Pending changes'), findsNothing);
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

    expect(find.text('Join requests'), findsNothing);
    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.textContaining('Jordan Lee'), findsNWidgets(2));
    expect(find.textContaining('Alex Rivera'), findsOneWidget);
    expect(find.text('Invite a New Member'), findsOneWidget);
    expect(find.text('Reported requests'), findsOneWidget);

    final membersTop = tester.getTopLeft(find.text('Members')).dy;
    final inviteTop = tester.getTopLeft(find.text('Invite a New Member')).dy;
    final reportsTop = tester.getTopLeft(find.text('Reported requests')).dy;
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

  testWidgets('profile screen manages name and exposes requests and logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(
            initialDisplayName: 'Sarah Chen',
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

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.text('Your prayer requests'), findsOneWidget);
    expect(find.text('Please pray'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
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

  testWidgets('home header uses title graphic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(appBar: HomeHeader())),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
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
    expect(titleGraphic.height, 96);
    expect(appBar.centerTitle, isTrue);
    expect(appBar.backgroundColor, Colors.transparent);
    expect(find.byTooltip('Profile'), findsOneWidget);
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
