import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/app.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/app_providers.dart';
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

void main() {
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
                requireApproval: true,
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
    await tester.pump();

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
                requireApproval: true,
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
    await tester.pump();

    expect(find.textContaining('Sarah Chen'), findsOneWidget);
    expect(find.textContaining('user-1'), findsNothing);
  });

  testWidgets('requester actions are hidden behind details menu', (
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
                requireApproval: true,
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
    await tester.pump();

    expect(find.text('Prayed'), findsNothing);
    expect(find.text('Follow up'), findsNothing);
    expect(find.text('Resolve'), findsNothing);
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Update'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz));
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
                requireApproval: true,
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
    await tester.pump();

    expect(find.text('Prayed'), findsNothing);

    await tester.tap(find.text('Please pray'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Please pray'));
    await tester.pumpAndSettle();

    expect(prayed, isTrue);
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
                requireApproval: true,
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
    expect(defaultGroupRequiresApproval, isFalse);
  });
}
