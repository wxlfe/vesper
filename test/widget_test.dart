import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/app.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/app_providers.dart';
import 'package:vesper/features/auth/data/auth_repository.dart';
import 'package:vesper/features/groups/data/group_repository.dart';
import 'package:vesper/features/requests/data/prayer_request_repository.dart';
import 'package:vesper/features/profile/data/user_profile_repository.dart';

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
  const _FakeGroupRepository(this.groups);

  final List<VesperGroup> groups;

  @override
  Stream<List<VesperGroup>> watchMyGroups() => Stream.value(groups);

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
  const _FakePrayerRequestRepository({this.requests = const []});

  final List<PrayerRequestSummary> requests;

  @override
  Stream<List<PrayerRequestSummary>> watchRequests(VesperGroup group) =>
      Stream.value(
        requests.where((request) => request.groupId == group.id).toList(),
      );

  @override
  Future<List<PrayerRequestSummary>> readCachedRequests(
    VesperGroup group,
  ) async => requests.where((request) => request.groupId == group.id).toList();

  @override
  Future<void> createRequest({
    required VesperGroup group,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> updateRequest({
    required VesperGroup group,
    required PrayerRequestSummary request,
    required String title,
    required String body,
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
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Submit prayer request'));
      await tester.pumpAndSettle();

      expect(find.text('Share a Prayer Request'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Morning Group'), findsOneWidget);
      expect(find.text('Evening Group'), findsOneWidget);
      expect(find.text('0 groups selected'), findsOneWidget);

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(find.text('2 groups selected'), findsOneWidget);
    },
  );

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

  testWidgets('prayer composer uses a larger request body field', (
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

    final requestField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Request'),
    );

    expect(requestField.minLines, 5);
    expect(requestField.maxLines, 8);
    expect(requestField.keyboardType, TextInputType.multiline);
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
                  onCreateRequest: ({required title, required body}) async {
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
    await tester.enterText(find.widgetWithText(TextField, 'Request'), 'Body');
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
    final bodyTop = tester.getTopLeft(find.text('Private request body')).dy;
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
