import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/app_providers.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/features/profile/data/user_profile_repository.dart';

class VesperApp extends ConsumerWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Vesper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: ref
          .watch(authStateProvider)
          .when(
            data: (user) =>
                user == null ? const AuthScreen() : const HomeScreen(),
            loading: () => const QuietLoadingScreen(),
            error: (error, stackTrace) => const AuthScreen(),
          ),
    );
  }
}

class QuietLoadingScreen extends StatelessWidget {
  const QuietLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text('Vesper', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Private prayer for trusted groups.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            if (_isSignUp)
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
            if (_isSignUp) const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_isSignUp ? 'Create account' : 'Sign in'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp ? 'I already have an account' : 'Create an account',
              ),
            ),
            const SizedBox(height: 24),
            const PrivacyNote(),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await auth.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
    } on Exception {
      if (mounted) {
        _showMessage(
          context,
          'We could not sign you in. Check your details and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vesper'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: StreamBuilder<List<VesperGroup>>(
        stream: ref.watch(groupRepositoryProvider).watchMyGroups(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <VesperGroup>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pinnedGroupIds =
              ref.watch(pinnedGroupIdsProvider).value ?? const <String>{};
          final unpinnedItems = items
              .where((group) => !pinnedGroupIds.contains(group.id))
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Your groups',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Share, pray, and follow up with people you trust.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const EmptyCard(
                  text: 'Create a group or enter an invite code to begin.',
                ),
              PinnedGroupsSection(
                groups: items,
                pinnedGroupIds: pinnedGroupIds,
                builder: (group) => GroupCard(group: group),
              ),
              if (unpinnedItems.isNotEmpty)
                Text(
                  'All Groups',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              for (final group in unpinnedItems) GroupCard(group: group),
            ],
          );
        },
      ),
      floatingActionButton: HomeGroupFab(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const GroupActionsSheet(),
        ),
      ),
    );
  }
}

class HomeGroupFab extends StatelessWidget {
  const HomeGroupFab({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Create or join group',
      child: const Icon(Icons.group_add_outlined),
    );
  }
}

class GroupCard extends ConsumerWidget {
  const GroupCard({super.key, required this.group});

  final VesperGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(groupRepositoryProvider);
    final pinnedGroupIds =
        ref.watch(pinnedGroupIdsProvider).value ?? const <String>{};
    final isPinned = pinnedGroupIds.contains(group.id);
    return GroupEntryMenu(
      pinLabel: isPinned ? 'Unpin' : 'Pin',
      onPin: () async {
        await ref.read(pinnedGroupServiceProvider).togglePinnedGroup(group.id);
        ref.invalidate(pinnedGroupIdsProvider);
        if (context.mounted) _showMessage(context, 'Pinned groups updated.');
      },
      onShare: () async {
        final invite = await repository.createInviteCode(group.id);
        await Clipboard.setData(ClipboardData(text: invite.code));
        if (context.mounted) {
          _showMessage(
            context,
            'Invite code copied. It expires ${DateFormat.MMMd().format(invite.expiresAt)}.',
          );
        }
      },
      onLeave: () => _showMessage(
        context,
        'Leaving groups will be added with membership safeguards.',
      ),
      child: Card(
        child: StreamBuilder<int>(
          stream: repository.watchRequestCount(group.id),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0;
            return ListTile(
              contentPadding: const EdgeInsets.all(20),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name),
                  Text(
                    group.description.isEmpty
                        ? 'Private to this group.'
                        : group.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              subtitle: Text('$total ${total == 1 ? 'request' : 'requests'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PinnedGroupsSection extends StatelessWidget {
  const PinnedGroupsSection({
    super.key,
    required this.groups,
    required this.pinnedGroupIds,
    required this.builder,
  });

  final List<VesperGroup> groups;
  final Set<String> pinnedGroupIds;
  final Widget Function(VesperGroup group) builder;

  @override
  Widget build(BuildContext context) {
    final pinned = groups
        .where((group) => pinnedGroupIds.contains(group.id))
        .toList();
    if (pinned.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pinned Groups', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final group in pinned) builder(group),
        const SizedBox(height: 20),
      ],
    );
  }
}

class EntryActionMenu extends StatelessWidget {
  const EntryActionMenu({
    super.key,
    required this.actions,
    required this.child,
  });

  final List<EntryAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) async {
        final selected = await showMenu<EntryAction>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            for (final action in actions)
              PopupMenuItem<EntryAction>(
                value: action,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon),
                    const SizedBox(width: 12),
                    Text(action.label),
                  ],
                ),
              ),
          ],
        );
        selected?.onSelected();
      },
      child: child,
    );
  }
}

class EntryAction {
  const EntryAction({
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
}

class GroupEntryMenu extends StatelessWidget {
  const GroupEntryMenu({
    super.key,
    required this.pinLabel,
    required this.onPin,
    required this.onShare,
    required this.onLeave,
    required this.child,
  });

  final String pinLabel;
  final VoidCallback onPin;
  final VoidCallback onShare;
  final VoidCallback onLeave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EntryActionMenu(
      actions: [
        EntryAction(
          label: pinLabel,
          icon: Icons.push_pin_outlined,
          onSelected: onPin,
        ),
        EntryAction(
          label: 'Share',
          icon: Icons.ios_share_outlined,
          onSelected: onShare,
        ),
        EntryAction(label: 'Leave', icon: Icons.logout, onSelected: onLeave),
      ],
      child: child,
    );
  }
}

class MemberEntryMenu extends StatelessWidget {
  const MemberEntryMenu({
    super.key,
    required this.onPromote,
    required this.onRemove,
    required this.child,
  });

  final VoidCallback onPromote;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EntryActionMenu(
      actions: [
        EntryAction(
          label: 'Promote',
          icon: Icons.arrow_upward,
          onSelected: onPromote,
        ),
        EntryAction(
          label: 'Remove',
          icon: Icons.person_remove_outlined,
          onSelected: onRemove,
        ),
      ],
      child: child,
    );
  }
}

class GroupActionsSheet extends ConsumerStatefulWidget {
  const GroupActionsSheet({super.key});

  @override
  ConsumerState<GroupActionsSheet> createState() => _GroupActionsSheetState();
}

const defaultGroupRequiresApproval = false;

class _GroupActionsSheetState extends ConsumerState<GroupActionsSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _inviteCode = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Create a group', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Group name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Short description'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _createGroup,
            child: const Text('Create group'),
          ),
          const Divider(height: 40),
          Text(
            'Join with a code',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inviteCode,
            decoration: const InputDecoration(labelText: 'Invite code'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _requestJoin,
            child: const Text('Request to join'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(groupRepositoryProvider)
          .createGroup(
            name: _name.text,
            description: _description.text,
            requireApproval: defaultGroupRequiresApproval,
          );
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        _showMessage(
          context,
          'We could not create the group. Try again in a moment.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestJoin() async {
    setState(() => _busy = true);
    try {
      await ref.read(groupRepositoryProvider).requestToJoin(_inviteCode.text);
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage(context, 'Your request was sent to the group Leaders.');
      }
    } on Exception {
      if (mounted) _showMessage(context, 'That invite code could not be used.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.group});

  final VesperGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<GroupMembership?>(
      stream: ref.watch(groupRepositoryProvider).watchMyMembership(group.id),
      builder: (context, snapshot) {
        final isLeader = snapshot.data?.isLeader ?? false;
        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              if (isLeader)
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GroupSettingsScreen(group: group),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              RequestList(group: group, isLeader: isLeader),
              const SizedBox(height: 20),
              GroupManagement(group: group, isLeader: isLeader),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => PrayerComposerSheet(group: group),
            ),
            label: const Text('New Request'),
            icon: const Icon(Icons.add_comment_outlined),
          ),
        );
      },
    );
  }
}

class PrayerComposerSheet extends ConsumerStatefulWidget {
  const PrayerComposerSheet({super.key, required this.group});

  final VesperGroup group;

  @override
  ConsumerState<PrayerComposerSheet> createState() =>
      _PrayerComposerSheetState();
}

class _PrayerComposerSheetState extends ConsumerState<PrayerComposerSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Share a Prayer Request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            decoration: const InputDecoration(labelText: 'Request'),
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Request Prayer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(prayerRequestRepositoryProvider)
          .createRequest(
            group: widget.group,
            title: _title.text,
            body: _body.text,
          );
      _title.clear();
      _body.clear();
      if (mounted) {
        _showMessage(
          context,
          widget.group.requireApproval
              ? 'Sent for Leader review.'
              : 'Shared with your group.',
        );
      }
    } on Exception {
      if (mounted) _showMessage(context, 'This request could not be saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class RequestList extends ConsumerWidget {
  const RequestList({super.key, required this.group, required this.isLeader});

  final VesperGroup group;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<PrayerRequestSummary>>(
      stream: ref
          .watch(prayerRequestRepositoryProvider)
          .watchRequests(group, includePending: isLeader),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FutureBuilder<List<PrayerRequestSummary>>(
            future: ref
                .watch(prayerRequestRepositoryProvider)
                .readCachedRequests(group),
            builder: (context, cached) => RequestCards(
              group: group,
              requests: cached.data ?? const [],
              isLeader: isLeader,
              offline: true,
            ),
          );
        }
        return RequestCards(
          group: group,
          requests: snapshot.data ?? const [],
          isLeader: isLeader,
          offline: false,
        );
      },
    );
  }
}

class RequestCards extends ConsumerWidget {
  const RequestCards({
    super.key,
    required this.group,
    required this.requests,
    required this.isLeader,
    required this.offline,
  });

  final VesperGroup group;
  final List<PrayerRequestSummary> requests;
  final bool isLeader;
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) return const EmptyCard(text: 'No requests yet.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (offline)
          Text(
            'Showing saved requests from this device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => RequestCard(
            group: group,
            request: requests[index],
            isLeader: isLeader,
          ),
        ),
      ],
    );
  }
}

class RequestCard extends ConsumerWidget {
  const RequestCard({
    super.key,
    required this.group,
    required this.request,
    required this.isLeader,
    this.currentUserId,
    this.onDoubleTapPrayed,
  });

  final VesperGroup group;
  final PrayerRequestSummary request;
  final bool isLeader;
  final String? currentUserId;
  final VoidCallback? onDoubleTapPrayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, String>>(
      future: ref.read(userProfileRepositoryProvider).displayNamesFor({
        request.createdBy,
      }),
      builder: (context, snapshot) {
        final authorName = displayNameFor(
          snapshot.data ?? const <String, String>{},
          request.createdBy,
        );
        final isRequester =
            (currentUserId ??
                ref.watch(authRepositoryProvider).currentUser?.uid) ==
            request.createdBy;
        return GestureDetector(
          onDoubleTap: isRequester
              ? null
              : onDoubleTapPrayed ??
                    () => ref
                        .read(prayerRequestRepositoryProvider)
                        .markPrayed(group.id, request.id),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(request.body),
                  const SizedBox(height: 12),
                  Text(
                    '$authorName · ${request.status.replaceAll('_', ' ')} · ${DateFormat.MMMd().format(request.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (isLeader && request.status == 'pending_approval')
                        OutlinedButton(
                          onPressed: () => ref
                              .read(prayerRequestRepositoryProvider)
                              .setStatus(request.id, 'active'),
                          child: const Text('Approve'),
                        ),
                      if (isLeader && !isRequester)
                        OutlinedButton(
                          onPressed: () => ref
                              .read(prayerRequestRepositoryProvider)
                              .setStatus(request.id, 'answered'),
                          child: const Text('Answered'),
                        ),
                      if (isRequester)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) {
                            if (value == 'update') {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => RequestUpdateSheet(
                                  group: group,
                                  request: request,
                                ),
                              );
                            }
                            if (value == 'remove') {
                              ref
                                  .read(prayerRequestRepositoryProvider)
                                  .removeRequest(request.id);
                            }
                            if (value == 'answered') {
                              ref
                                  .read(prayerRequestRepositoryProvider)
                                  .setStatus(request.id, 'answered');
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'update',
                              child: Text('Update'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                            PopupMenuItem(
                              value: 'answered',
                              child: Text('Answered'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RequestUpdateSheet extends ConsumerStatefulWidget {
  const RequestUpdateSheet({
    super.key,
    required this.group,
    required this.request,
  });

  final VesperGroup group;
  final PrayerRequestSummary request;

  @override
  ConsumerState<RequestUpdateSheet> createState() => _RequestUpdateSheetState();
}

class _RequestUpdateSheetState extends ConsumerState<RequestUpdateSheet> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.request.title);
    _body = TextEditingController(text: widget.request.body);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Update request', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            decoration: const InputDecoration(labelText: 'Request'),
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Save update'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(prayerRequestRepositoryProvider)
          .updateRequest(
            group: widget.group,
            request: widget.request,
            title: _title.text,
            body: _body.text,
          );
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) _showMessage(context, 'This request could not be updated.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class ProfileNameText extends ConsumerWidget {
  const ProfileNameText({super.key, required this.userId, this.prefix = ''});

  final String userId;
  final String prefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, String>>(
      future: ref.read(userProfileRepositoryProvider).displayNamesFor({userId}),
      builder: (context, snapshot) {
        final name = displayNameFor(
          snapshot.data ?? const <String, String>{},
          userId,
        );
        return Text('$prefix$name');
      },
    );
  }
}

class GroupManagement extends ConsumerWidget {
  const GroupManagement({
    super.key,
    required this.group,
    required this.isLeader,
  });

  final VesperGroup group;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(groupRepositoryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group care', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final invite = await repository.createInviteCode(group.id);
                await Clipboard.setData(ClipboardData(text: invite.code));
                if (context.mounted) {
                  _showMessage(
                    context,
                    'Invite code copied. It expires ${DateFormat.MMMd().format(invite.expiresAt)}.',
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy invite code'),
            ),
            if (isLeader) ...[
              const Divider(height: 32),
              Text(
                'Join requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              StreamBuilder<List<JoinRequest>>(
                stream: repository.watchJoinRequests(group.id),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? const <JoinRequest>[];
                  if (requests.isEmpty) {
                    return Text(
                      'No one is waiting to join.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: [
                      for (final request in requests)
                        ListTile(
                          title: ProfileNameText(
                            userId: request.requestedBy,
                            prefix: 'Request from ',
                          ),
                          subtitle: request.invitedBy == null
                              ? const Text('Inviter unknown')
                              : ProfileNameText(
                                  userId: request.invitedBy!,
                                  prefix: 'Invited by ',
                                ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    repository.approveJoinRequest(request),
                                icon: const Icon(Icons.check),
                                tooltip: 'Approve',
                              ),
                              IconButton(
                                onPressed: () =>
                                    repository.rejectJoinRequest(request),
                                icon: const Icon(Icons.close),
                                tooltip: 'Reject',
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),
              Text(
                'Settings changes are handled in Group Settings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({super.key, required this.group});

  final VesperGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(groupRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Group Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publishing',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.requireApproval
                        ? 'Requests currently wait for Leader approval.'
                        : 'Requests currently publish immediately.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await repository.proposePublishingPolicy(
                        group.id,
                        !group.requireApproval,
                      );
                      if (context.mounted) {
                        _showMessage(context, 'Settings change proposed.');
                      }
                    },
                    child: Text(
                      group.requireApproval
                          ? 'Propose publish immediately'
                          : 'Propose Leader approval',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          MemberSettings(group: group),
          const SizedBox(height: 16),
          SettingsChangeList(group: group),
        ],
      ),
    );
  }
}

class MemberSettings extends ConsumerWidget {
  const MemberSettings({super.key, required this.group});

  final VesperGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(groupRepositoryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<GroupMembership>>(
          stream: repository.watchMembers(group.id),
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <GroupMembership>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Members', style: Theme.of(context).textTheme.titleLarge),
                for (final member in members)
                  member.role == 'member'
                      ? MemberEntryMenu(
                          onPromote: () async {
                            await repository.proposeLeaderAddition(
                              group.id,
                              member.userId,
                            );
                            if (context.mounted) {
                              _showMessage(
                                context,
                                'Promotion proposed for Leader review.',
                              );
                            }
                          },
                          onRemove: () async {
                            await repository.proposeMemberRemoval(
                              group.id,
                              member.userId,
                            );
                            if (context.mounted) {
                              _showMessage(
                                context,
                                'Removal proposed for Leader review.',
                              );
                            }
                          },
                          child: ListTile(
                            title: ProfileNameText(userId: member.userId),
                            subtitle: const Text('Member'),
                          ),
                        )
                      : ListTile(
                          title: ProfileNameText(userId: member.userId),
                          subtitle: const Text('Leader'),
                        ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SettingsChangeList extends ConsumerWidget {
  const SettingsChangeList({super.key, required this.group});

  final VesperGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(groupRepositoryProvider);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.watchSettingsChanges(group.id),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending changes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (docs.isEmpty)
                  Text(
                    'No pending settings changes.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                for (final doc in docs)
                  ListTile(
                    title: SettingsChangeTitle(data: doc.data()),
                    subtitle: const Text('Visible only to Leaders'),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: () =>
                              repository.approveSettingsChange(doc.id),
                          icon: const Icon(Icons.check),
                          tooltip: 'Approve',
                        ),
                        IconButton(
                          onPressed: () =>
                              repository.disputeSettingsChange(doc.id),
                          icon: const Icon(Icons.block),
                          tooltip: 'Dispute',
                        ),
                      ],
                    ),
                  ),
                OutlinedButton(
                  onPressed: () =>
                      repository.maybeFinalizeSettingsChanges(group.id),
                  child: const Text('Apply ready changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsChangeTitle extends ConsumerWidget {
  const SettingsChangeTitle({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data['type'] == 'publishing_policy') {
      final settings =
          data['proposedSettings'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      return Text(
        settings['requireApproval'] == true
            ? 'Require Leader approval'
            : 'Publish requests immediately',
      );
    }

    final targetUserId = (data['targetUserId'] as String?) ?? '';
    return FutureBuilder<Map<String, String>>(
      future: ref.read(userProfileRepositoryProvider).displayNamesFor({
        targetUserId,
      }),
      builder: (context, snapshot) {
        final name = displayNameFor(
          snapshot.data ?? const <String, String>{},
          targetUserId,
        );
        if (data['type'] == 'remove_member') {
          return Text('Remove $name from group');
        }
        return Text('Add $name as Leader');
      },
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.initialDisplayName,
    this.requests,
    this.onSaveName,
    this.onLogout,
  });

  final String? initialDisplayName;
  final List<PrayerRequestSummary>? requests;
  final Future<void> Function(String name)? onSaveName;
  final Future<void> Function()? onLogout;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final currentName =
        widget.initialDisplayName ??
        ref.read(authRepositoryProvider).currentUser?.displayName ??
        '';
    _name = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _saveName,
              child: const Text('Save name'),
            ),
            const SizedBox(height: 32),
            Text(
              'Your prayer requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (widget.requests != null)
              ProfileRequestList(requests: widget.requests!)
            else
              const MyPrayerRequestsAcrossGroups(),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _busy ? null : _logout,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    setState(() => _busy = true);
    try {
      if (widget.onSaveName != null) {
        await widget.onSaveName!(_name.text);
      } else {
        await ref.read(authRepositoryProvider).updateDisplayName(_name.text);
      }
      if (mounted) _showMessage(context, 'Name updated.');
    } on Exception {
      if (mounted) _showMessage(context, 'We could not update your name.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      if (widget.onLogout != null) {
        await widget.onLogout!();
      } else {
        await ref.read(authRepositoryProvider).signOut();
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class MyPrayerRequestsAcrossGroups extends ConsumerWidget {
  const MyPrayerRequestsAcrossGroups({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (userId == null) {
      return const EmptyCard(text: 'Sign in to see your requests.');
    }
    return StreamBuilder<List<VesperGroup>>(
      stream: ref.watch(groupRepositoryProvider).watchMyGroups(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const <VesperGroup>[];
        if (groups.isEmpty) {
          return const EmptyCard(text: 'Your requests will appear here.');
        }
        return Column(
          children: [
            for (final group in groups)
              MyPrayerRequestsForGroup(group: group, userId: userId),
          ],
        );
      },
    );
  }
}

class MyPrayerRequestsForGroup extends ConsumerWidget {
  const MyPrayerRequestsForGroup({
    super.key,
    required this.group,
    required this.userId,
  });

  final VesperGroup group;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<PrayerRequestSummary>>(
      stream: ref
          .watch(prayerRequestRepositoryProvider)
          .watchRequests(group, includePending: true),
      builder: (context, snapshot) {
        final requests = (snapshot.data ?? const <PrayerRequestSummary>[])
            .where((request) => request.createdBy == userId)
            .toList();
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name, style: Theme.of(context).textTheme.bodyMedium),
            ProfileRequestList(requests: requests),
          ],
        );
      },
    );
  }
}

class ProfileRequestList extends StatelessWidget {
  const ProfileRequestList({super.key, required this.requests});

  final List<PrayerRequestSummary> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const EmptyCard(text: 'Your requests will appear here.');
    }
    return Column(
      children: [
        for (final request in requests)
          Card(
            child: ListTile(
              title: Text(request.title),
              subtitle: Text(
                '${request.status.replaceAll('_', ' ')} · ${DateFormat.MMMd().format(request.createdAt)}',
              ),
            ),
          ),
      ],
    );
  }
}

class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'End-to-end encrypted. Vesper cannot read prayer contents.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: Text(text)),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
