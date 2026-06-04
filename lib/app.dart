import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/app_providers.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/core/widgets/manuscript_widgets.dart';
import 'package:vesper/features/groups/data/group_repository.dart';
import 'package:vesper/features/profile/data/user_profile_repository.dart';
import 'package:vesper/shared/rich_text/rich_text_widgets.dart';

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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeHeader(),
      body: _selectedIndex == 0 ? const PrayTab() : const GroupsTab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openRequestComposer,
        tooltip: 'Submit prayer request',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 0),
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('Pray'),
              ),
            ),
            const SizedBox(width: 72),
            Expanded(
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Groups'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRequestComposer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StreamBuilder<List<VesperGroup>>(
        stream: ref.read(groupRepositoryProvider).watchMyGroups(),
        builder: (context, snapshot) {
          return PrayerComposerSheet(groups: snapshot.data ?? const []);
        },
      ),
    );
  }
}

class PrayTab extends ConsumerWidget {
  const PrayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<VesperGroup>>(
      stream: ref.watch(groupRepositoryProvider).watchMyGroups(),
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const <VesperGroup>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Pray', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const RoutineRow(),
            const SizedBox(height: 20),
            Text(
              'Prayer requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (snapshot.hasError) ...[
              Builder(
                builder: (context) {
                  logGroupStreamError(snapshot.error, snapshot.stackTrace);
                  return const EmptyCard(
                    text: 'We could not load your groups.',
                  );
                },
              ),
            ] else if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (groups.isEmpty)
              const EmptyCard(
                text: 'Requests from your groups will appear here.',
              )
            else
              ConsolidatedRequestFeed(groups: groups),
          ],
        );
      },
    );
  }
}

class RoutineRow extends ConsumerWidget {
  const RoutineRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<PrayerSession>>(
      stream: ref.watch(prayerSessionRepositoryProvider).watchSessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <PrayerSession>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your routines',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const CreateRoutineButton(),
                  for (final session in sessions)
                    RoutineCircle(session: session),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class RoutineCircle extends StatelessWidget {
  const RoutineCircle({super.key, required this.session});

  final PrayerSession session;

  @override
  Widget build(BuildContext context) {
    final initial = session.name.trim().isEmpty
        ? 'R'
        : session.name.trim().characters.first.toUpperCase();
    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoutineReaderScreen(session: session),
          ),
        ),
        borderRadius: BorderRadius.circular(48),
        child: Column(
          children: [
            CircleAvatar(radius: 30, child: Text(initial)),
            const SizedBox(height: 8),
            Text(session.name, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class CreateRoutineButton extends StatelessWidget {
  const CreateRoutineButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CreateRoutineSheet(),
        ),
        borderRadius: BorderRadius.circular(48),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            const Text('Create Routine', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class CreateRoutineSheet extends ConsumerStatefulWidget {
  const CreateRoutineSheet({super.key});

  @override
  ConsumerState<CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<CreateRoutineSheet> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _errorText;

  @override
  void dispose() {
    _name.dispose();
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
            'Create a routine',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Routine name'),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            textInputAction: TextInputAction.done,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _errorText!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _create,
            child: const Text('Create Routine'),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _errorText = 'Name this routine first.');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final session = await ref
          .read(prayerSessionRepositoryProvider)
          .createSession(_name.text);
      await ref
          .read(prayerSessionRepositoryProvider)
          .addSection(
            sessionId: session.id,
            type: RoutineSectionType.requestFeed,
            title: 'Prayer requests',
            contentDeltaJson: emptyRoutineDeltaJson(),
          );
      if (mounted) {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => RoutineReaderScreen(session: session),
          ),
        );
      }
    } catch (error, stackTrace) {
      logRoutineCreationError(error, stackTrace);
      if (mounted) {
        setState(() => _errorText = 'This routine could not be created.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

void logRoutineCreationError(Object error, StackTrace stackTrace) {
  if (error is FirebaseException) {
    debugPrint(
      'Routine creation error: FirebaseException code=${error.code} message=${error.message}',
    );
    debugPrint('Routine creation stack: $stackTrace');
    return;
  }
  debugPrint('Routine creation error: ${error.runtimeType}');
  debugPrint('Routine creation stack: $stackTrace');
}

class RoutineReaderScreen extends ConsumerWidget {
  const RoutineReaderScreen({super.key, required this.session});

  final PrayerSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.name),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RoutineEditScreen(session: session),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit routine',
          ),
        ],
      ),
      body: StreamBuilder<List<RoutineSection>>(
        stream: ref
            .watch(prayerSessionRepositoryProvider)
            .watchSections(session.id),
        builder: (context, snapshot) {
          final sections = sortedRoutineSections(snapshot.data ?? const []);
          if (sections.isEmpty) {
            return const Center(
              child: EmptyCard(text: 'Add a section to begin this routine.'),
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: sections.length,
            itemBuilder: (context, index) => RoutineStepPage(
              session: session,
              section: sections[index],
              stepNumber: index + 1,
              stepCount: sections.length,
            ),
          );
        },
      ),
    );
  }
}

class RoutineStepPage extends StatelessWidget {
  const RoutineStepPage({
    super.key,
    required this.session,
    required this.section,
    required this.stepNumber,
    required this.stepCount,
  });

  final PrayerSession session;
  final RoutineSection section;
  final int stepNumber;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step $stepNumber of $stepCount',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              section.title.isEmpty ? session.name : section.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: RoutineSectionBody(section: section),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutineSectionBody extends ConsumerWidget {
  const RoutineSectionBody({super.key, required this.section});

  final RoutineSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section.type == RoutineSectionType.requestFeed) {
      return StreamBuilder<List<VesperGroup>>(
        stream: ref.watch(groupRepositoryProvider).watchMyGroups(),
        builder: (context, snapshot) {
          final groups = snapshot.data ?? const <VesperGroup>[];
          if (groups.isEmpty) {
            return const Text('No requests are ready here yet.');
          }
          return ConsolidatedRequestFeed(groups: groups);
        },
      );
    }
    return RoutineSectionContentCard(
      contentDeltaJson: section.contentDeltaJson,
    );
  }
}

class RoutineSectionContentCard extends StatelessWidget {
  const RoutineSectionContentCard({super.key, required this.contentDeltaJson});

  final String contentDeltaJson;

  @override
  Widget build(BuildContext context) {
    return ManuscriptCard(
      innerBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [RichTextContentViewer(deltaJson: contentDeltaJson)],
      ),
    );
  }
}

quill.QuillController routineQuillControllerFromDeltaJson(
  String deltaJson, {
  bool readOnly = false,
}) {
  return richTextControllerFromDeltaJson(deltaJson, readOnly: readOnly);
}

String routineQuillControllerToDeltaJson(quill.QuillController controller) {
  return richTextControllerToDeltaJson(controller);
}

quill.Attribute routineFormatAttributeForToggle(
  quill.QuillController controller,
  quill.Attribute attribute,
) {
  return richTextFormatAttributeForToggle(controller, attribute);
}

class RoutineEditScreen extends ConsumerStatefulWidget {
  const RoutineEditScreen({super.key, required this.session});

  final PrayerSession session;

  @override
  ConsumerState<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.text = widget.session.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoutineSection>>(
      stream: ref
          .watch(prayerSessionRepositoryProvider)
          .watchSections(widget.session.id),
      builder: (context, snapshot) {
        final sections = sortedRoutineSections(snapshot.data ?? const []);
        return Scaffold(
          appBar: AppBar(title: const Text('Edit routine')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Routine name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _busy ? null : _saveName,
                    child: const Text('Save routine name'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sections',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (sections.isEmpty)
                    const EmptyCard(text: 'Add a section to begin.')
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: sections.length,
                      onReorder: _busy
                          ? (_, _) {}
                          : (oldIndex, newIndex) =>
                                _reorderSections(oldIndex, newIndex, sections),
                      itemBuilder: (context, index) => _RoutineSectionTile(
                        key: ValueKey(sections[index].id),
                        index: index,
                        section: sections[index],
                        busy: _busy,
                        onEdit: _openSectionEditor,
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _archiveRoutine,
                    child: const Text('Archive routine'),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add section',
            onPressed: _busy ? null : () => _addFromFab(sections),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _saveName() async {
    if (_name.text.trim().isEmpty) {
      _showMessage(context, 'Name this routine first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(prayerSessionRepositoryProvider)
          .updateSessionName(widget.session, _name.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Routine name updated.')));
      }
    } on Exception {
      if (mounted) _showMessage(context, 'Could not rename routine.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorderSections(
    int oldIndex,
    int newIndex,
    List<RoutineSection> sections,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final reordered = [...sections];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() => _busy = true);
    try {
      for (var index = 0; index < reordered.length; index += 1) {
        final section = reordered[index];
        final sortOrder = (index + 1) * 1000;
        if (section.sortOrder == sortOrder) continue;
        await ref
            .read(prayerSessionRepositoryProvider)
            .updateSection(section.copyWith(sortOrder: sortOrder));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSection(RoutineSectionType type) async {
    setState(() => _busy = true);
    try {
      final title = switch (type) {
        RoutineSectionType.customText => 'Section',
        RoutineSectionType.requestFeed => 'Prayer requests',
        RoutineSectionType.silence => 'Section',
        RoutineSectionType.readingPlaceholder => 'Section',
      };
      await ref
          .read(prayerSessionRepositoryProvider)
          .addSection(
            sessionId: widget.session.id,
            type: type,
            title: title,
            contentDeltaJson: emptyRoutineDeltaJson(),
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFromFab(List<RoutineSection> sections) async {
    final hasRequestFeed = sections.any(
      (section) => section.type == RoutineSectionType.requestFeed,
    );
    if (hasRequestFeed) {
      await _addSection(RoutineSectionType.customText);
      return;
    }
    await _showAddSectionSheet();
  }

  void _openSectionEditor(RoutineSection section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineSectionEditScreen(section: section),
      ),
    );
  }

  Future<void> _showAddSectionSheet() async {
    final type = await showModalBottomSheet<RoutineSectionType>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Add section', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('add-section-custom_text'),
              title: Text(
                routineSectionTypeLabel(RoutineSectionType.customText),
              ),
              onTap: () =>
                  Navigator.of(context).pop(RoutineSectionType.customText),
            ),
            ListTile(
              key: const ValueKey('add-section-request_feed'),
              title: const Text('Request feed'),
              onTap: () =>
                  Navigator.of(context).pop(RoutineSectionType.requestFeed),
            ),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;
    await _addSection(type);
  }

  Future<void> _archiveRoutine() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(prayerSessionRepositoryProvider)
          .archiveSession(widget.session.id);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class RoutineSectionEditScreen extends ConsumerStatefulWidget {
  const RoutineSectionEditScreen({super.key, required this.section});

  final RoutineSection section;

  @override
  ConsumerState<RoutineSectionEditScreen> createState() =>
      _RoutineSectionEditScreenState();
}

class _RoutineSectionEditScreenState
    extends ConsumerState<RoutineSectionEditScreen> {
  final _title = TextEditingController();
  final _contentFocusNode = FocusNode();
  final _contentScrollController = ScrollController();
  late final quill.QuillController _content;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title.text = widget.section.title;
    _content = routineQuillControllerFromDeltaJson(
      widget.section.contentDeltaJson,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _contentFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = routineSectionDisplayTitle(widget.section);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit section')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routineSectionTypeLabel(widget.section.type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Section title'),
              ),
              const SizedBox(height: 12),
              Text(
                'Section text',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              RichTextFormatToolbar(
                controller: _content,
                focusNode: _contentFocusNode,
                busy: _busy,
              ),
              const SizedBox(height: 8),
              ManuscriptCard(
                padding: const EdgeInsets.all(12),
                innerBorder: true,
                child: RichTextContentEditor(
                  controller: _content,
                  focusNode: _contentFocusNode,
                  scrollController: _contentScrollController,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _save,
                    child: const Text('Save section'),
                  ),
                  Tooltip(
                    message: 'Remove $title',
                    child: TextButton.icon(
                      onPressed: _busy ? null : _remove,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref
          .read(prayerSessionRepositoryProvider)
          .updateSection(
            widget.section.copyWith(
              title: _title.text,
              contentDeltaJson: routineQuillControllerToDeltaJson(_content),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(prayerSessionRepositoryProvider)
          .removeSection(widget.section.id);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _RoutineSectionTile extends StatelessWidget {
  const _RoutineSectionTile({
    super.key,
    required this.index,
    required this.section,
    required this.busy,
    required this.onEdit,
  });

  final int index;
  final RoutineSection section;
  final bool busy;
  final ValueChanged<RoutineSection> onEdit;

  @override
  Widget build(BuildContext context) {
    final title = routineSectionDisplayTitle(section);
    return ManuscriptCard(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          enabled: !busy,
          child: Semantics(
            label: 'Reorder $title',
            button: true,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.drag_handle),
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text(routineSectionTypeLabel(section.type)),
        trailing: IconButton(
          tooltip: 'Edit $title',
          onPressed: busy ? null : () => onEdit(section),
          icon: const Icon(Icons.edit_outlined),
        ),
        onTap: busy ? null : () => onEdit(section),
      ),
    );
  }
}

extension on RoutineSection {
  RoutineSection copyWith({
    int? sortOrder,
    String? title,
    String? contentDeltaJson,
  }) {
    return RoutineSection(
      id: id,
      sessionId: sessionId,
      userId: userId,
      type: type,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status,
      title: title ?? this.title,
      contentDeltaJson: contentDeltaJson ?? this.contentDeltaJson,
    );
  }
}

String routineSectionDisplayTitle(RoutineSection section) {
  final title = section.title.trim();
  return title.isEmpty ? routineSectionTypeLabel(section.type) : title;
}

String routineSectionTypeLabel(RoutineSectionType type) {
  return switch (type) {
    RoutineSectionType.customText => 'Section',
    RoutineSectionType.requestFeed => 'Request feed',
    RoutineSectionType.silence => 'Section',
    RoutineSectionType.readingPlaceholder => 'Section',
  };
}

class ConsolidatedRequestFeed extends StatelessWidget {
  const ConsolidatedRequestFeed({super.key, required this.groups});

  final List<VesperGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RequestList(group: group, isLeader: false),
          ),
      ],
    );
  }
}

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<VesperGroup>>(
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
            OutlinedButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const GroupActionsSheet(),
              ),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Create or join group'),
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
              Text('All Groups', style: Theme.of(context).textTheme.titleLarge),
            for (final group in unpinnedItems) GroupCard(group: group),
          ],
        );
      },
    );
  }
}

class LegacyGroupsHomeScreen extends ConsumerWidget {
  const LegacyGroupsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const HomeHeader(),
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

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({super.key});

  static const double height = 96;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: height,
      centerTitle: true,
      title: Image.asset(
        'assets/title-graphic.png',
        key: const Key('home-title-graphic'),
        height: height,
        fit: BoxFit.contain,
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
        ),
      ],
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
      child: ManuscriptCard(
        child: StreamBuilder<int>(
          stream: repository.watchRequestCount(group.id),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RubricText('Private group'),
                  const SizedBox(height: 6),
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.description.isEmpty
                        ? 'Private to this group.'
                        : group.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('$total ${total == 1 ? 'request' : 'requests'}'),
              ),
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
  const GroupActionsSheet({super.key, this.onRequestJoin, this.scanner});

  final Future<void> Function(String code)? onRequestJoin;
  final InviteQrScannerBuilder? scanner;

  @override
  ConsumerState<GroupActionsSheet> createState() => _GroupActionsSheetState();
}

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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scanInviteCode,
            icon: const Icon(Icons.qr_code_scanner_outlined),
            label: const Text('Scan Invite QR Code'),
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
          .createGroup(name: _name.text, description: _description.text);
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
      await _requestJoinWithCode(_inviteCode.text);
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

  Future<void> _requestJoinWithCode(String code) {
    final requestJoin = widget.onRequestJoin;
    if (requestJoin != null) return requestJoin(code);
    return ref.read(groupRepositoryProvider).requestToJoin(code);
  }

  Future<void> _scanInviteCode() async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InviteQrScanner(
        scanner: widget.scanner,
        onRequestJoin: _requestJoinWithCode,
      ),
    );
    if (!mounted || joined != true) return;
    Navigator.of(context).pop();
    _showMessage(context, 'Your request was sent to the group Leaders.');
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
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        GroupSettingsScreen(group: group, isLeader: isLeader),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [RequestList(group: group, isLeader: isLeader)],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => PrayerComposerSheet(group: group),
            ),
            tooltip: 'Submit prayer request',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

typedef CreatePrayerRequest =
    Future<void> Function({
      required String title,
      required String body,
      required String bodyDeltaJson,
    });

enum _RequestComposerStep { compose, groups }

class PrayerComposerSheet extends ConsumerStatefulWidget {
  const PrayerComposerSheet({
    super.key,
    this.group,
    this.groups,
    this.onCreateRequest,
  });

  final VesperGroup? group;
  final List<VesperGroup>? groups;
  final CreatePrayerRequest? onCreateRequest;

  @override
  ConsumerState<PrayerComposerSheet> createState() =>
      _PrayerComposerSheetState();
}

class _PrayerComposerSheetState extends ConsumerState<PrayerComposerSheet> {
  final _title = TextEditingController();
  late final quill.QuillController _body;
  final _bodyFocusNode = FocusNode();
  final _bodyScrollController = ScrollController();
  final Set<String> _selectedGroupIds = <String>{};
  _RequestComposerStep _step = _RequestComposerStep.compose;
  bool _busy = false;

  List<VesperGroup> get _groups {
    final groups = widget.groups;
    if (groups != null) return groups;
    final group = widget.group;
    return group == null ? const <VesperGroup>[] : [group];
  }

  bool get _showGroupSelector => widget.groups != null;

  @override
  void initState() {
    super.initState();
    _body = richTextControllerFromDeltaJson(emptyRichTextDeltaJson());
    final group = widget.group;
    if (group != null && widget.groups == null) {
      _selectedGroupIds.add(group.id);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _bodyFocusNode.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showGroupStep =
        _showGroupSelector && _step == _RequestComposerStep.groups;
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
            showGroupStep ? 'Choose groups' : 'Share a Prayer Request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (!showGroupStep) ...[
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            Text('Request', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            RichTextFormatToolbar(
              controller: _body,
              focusNode: _bodyFocusNode,
              busy: _busy,
            ),
            const SizedBox(height: 8),
            ManuscriptCard(
              padding: const EdgeInsets.all(12),
              innerBorder: true,
              child: RichTextContentEditor(
                controller: _body,
                focusNode: _bodyFocusNode,
                scrollController: _bodyScrollController,
                minHeight: 80,
                maxHeight: 160,
              ),
            ),
          ],
          if (showGroupStep) ...[
            CheckboxListTile(
              value:
                  _groups.isNotEmpty &&
                  _selectedGroupIds.length == _groups.length,
              onChanged: _groups.isEmpty
                  ? null
                  : (selected) {
                      setState(() {
                        _selectedGroupIds.clear();
                        if (selected ?? false) {
                          _selectedGroupIds.addAll(
                            _groups.map((group) => group.id),
                          );
                        }
                      });
                    },
              title: const Text('Select All'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            for (final group in _groups)
              CheckboxListTile(
                value: _selectedGroupIds.contains(group.id),
                onChanged: (selected) {
                  setState(() {
                    if (selected ?? false) {
                      _selectedGroupIds.add(group.id);
                    } else {
                      _selectedGroupIds.remove(group.id);
                    }
                  });
                },
                title: Text(group.name),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            Text(
              '${_selectedGroupIds.length} ${_selectedGroupIds.length == 1 ? 'group' : 'groups'} selected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          if (showGroupStep)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(
                          () => _step = _RequestComposerStep.compose,
                        ),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: const Text('Request Prayer'),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : _showGroupSelector
                  ? _continueToGroups
                  : _submit,
              child: Text(_showGroupSelector ? 'Continue' : 'Request Prayer'),
            ),
        ],
      ),
    );
  }

  void _continueToGroups() {
    FocusScope.of(context).unfocus();
    setState(() => _step = _RequestComposerStep.groups);
  }

  Future<void> _submit() async {
    final selectedGroups = _groups
        .where((group) => _selectedGroupIds.contains(group.id))
        .toList();
    if (selectedGroups.isEmpty) {
      _showMessage(context, 'Choose at least one group to share this request.');
      return;
    }
    setState(() => _busy = true);
    try {
      final bodyDeltaJson = richTextControllerToDeltaJson(_body);
      final body = plainTextFromRichTextDeltaJson(bodyDeltaJson);
      final createRequest = widget.onCreateRequest;
      if (createRequest == null) {
        final repository = ref.read(prayerRequestRepositoryProvider);
        for (final group in selectedGroups) {
          await repository.createRequest(
            group: group,
            title: _title.text,
            body: body,
            bodyDeltaJson: bodyDeltaJson,
          );
        }
      } else {
        await createRequest(
          title: _title.text,
          body: body,
          bodyDeltaJson: bodyDeltaJson,
        );
      }
      _title.clear();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Shared with your group.')),
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
      stream: ref.watch(prayerRequestRepositoryProvider).watchRequests(group),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logRequestStreamError(snapshot.error, snapshot.stackTrace);
          return EmptyCard(
            text: 'We could not load requests for ${group.name}.',
          );
        }
        return StreamBuilder<Map<String, PrayerActivity>>(
          stream: ref
              .watch(prayerRequestRepositoryProvider)
              .watchPrayerActivity(group.id),
          builder: (context, activitySnapshot) => RequestCards(
            group: group,
            requests: snapshot.data ?? const [],
            isLeader: isLeader,
            offline: false,
            prayerActivityByRequest: activitySnapshot.data ?? const {},
          ),
        );
      },
    );
  }
}

void logRequestStreamError(Object? error, StackTrace? stackTrace) {
  debugPrint('Request stream error: $error');
  if (stackTrace != null) {
    debugPrint('Request stream stack: $stackTrace');
  }
}

void logGroupStreamError(Object? error, StackTrace? stackTrace) {
  debugPrint('Group stream error: $error');
  if (stackTrace != null) {
    debugPrint('Group stream stack: $stackTrace');
  }
}

class RequestCards extends ConsumerWidget {
  const RequestCards({
    super.key,
    required this.group,
    required this.requests,
    required this.isLeader,
    required this.offline,
    this.prayerActivityByRequest = const {},
    this.currentUserId,
  });

  final VesperGroup group;
  final List<PrayerRequestSummary> requests;
  final bool isLeader;
  final bool offline;
  final Map<String, PrayerActivity> prayerActivityByRequest;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) return const EmptyCard(text: 'No requests yet.');
    final sortedRequests = [...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
          itemCount: sortedRequests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => RequestCard(
            group: group,
            request: sortedRequests[index],
            isLeader: isLeader,
            prayerActivity: prayerActivityByRequest[sortedRequests[index].id],
            currentUserId: currentUserId,
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
    this.prayerActivity,
    this.onJoinPrayer,
    this.onDoubleTapPrayed,
    this.onReportRequest,
    this.onRemoveRequest,
  });

  final VesperGroup group;
  final PrayerRequestSummary request;
  final bool isLeader;
  final String? currentUserId;
  final PrayerActivity? prayerActivity;
  final VoidCallback? onJoinPrayer;
  final VoidCallback? onDoubleTapPrayed;
  final VoidCallback? onReportRequest;
  final VoidCallback? onRemoveRequest;

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
        final activity =
            prayerActivity ??
            const PrayerActivity(prayedCount: 0, hasCurrentUserPrayed: false);
        return ManuscriptCard(
          innerBorder: true,
          accentColor: Theme.of(context).colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onDoubleTap: isRequester
                    ? null
                    : onDoubleTapPrayed ??
                          () => ref
                              .read(prayerRequestRepositoryProvider)
                              .markPrayed(group.id, request.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RubricText(
                                group.name,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                request.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$authorName · ${request.status.replaceAll('_', ' ')} · ${DateFormat.MMMd().format(request.createdAt)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Request actions',
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
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
                              if (isRequester) {
                                await ref
                                    .read(prayerRequestRepositoryProvider)
                                    .removeRequest(request.id);
                              } else {
                                onRemoveRequest?.call();
                                if (onRemoveRequest == null &&
                                    context.mounted) {
                                  await _confirmRemoveRequest(
                                    context,
                                    ref,
                                    request.id,
                                  );
                                }
                              }
                            }
                            if (value == 'answered') {
                              await ref
                                  .read(prayerRequestRepositoryProvider)
                                  .setStatus(request.id, 'answered');
                            }
                            if (value == 'report') {
                              if (onReportRequest != null) {
                                onReportRequest!.call();
                                return;
                              }
                              await ref
                                  .read(prayerRequestRepositoryProvider)
                                  .reportRequest(group.id, request.id);
                              if (context.mounted) {
                                _showMessage(
                                  context,
                                  'This request was reported to Leaders.',
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            if (isRequester)
                              const PopupMenuItem(
                                value: 'update',
                                child: Text('Update'),
                              ),
                            if (isRequester || isLeader)
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove'),
                              ),
                            if (isRequester)
                              const PopupMenuItem(
                                value: 'answered',
                                child: Text('Answered'),
                              ),
                            if (!isRequester)
                              const PopupMenuItem(
                                value: 'report',
                                child: Text('Report'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const IlluminatedDivider(compact: true),
                    RichTextContentViewer(
                      deltaJson: request.bodyDeltaJson.trim().isEmpty
                          ? plainTextToRichTextDeltaJson(request.body)
                          : request.bodyDeltaJson,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              JoiningPrayerText(
                prayedCount: activity.prayedCount,
                hasCurrentUserPrayed: activity.hasCurrentUserPrayed,
                isRequester: isRequester,
                onJoin: isRequester || activity.hasCurrentUserPrayed
                    ? null
                    : () async {
                        final joinPrayer = onJoinPrayer;
                        if (joinPrayer != null) {
                          joinPrayer();
                          return;
                        }
                        try {
                          await ref
                              .read(prayerRequestRepositoryProvider)
                              .markPrayed(group.id, request.id);
                        } on Exception {
                          if (context.mounted) {
                            _showMessage(
                              context,
                              'This could not be saved. Try again when you’re online.',
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}

String? joiningPrayerText({
  required int prayedCount,
  required bool hasCurrentUserPrayed,
  required bool isRequester,
}) {
  if (prayedCount == 0) return null;
  if (!isRequester && hasCurrentUserPrayed) {
    final others = prayedCount > 0 ? prayedCount - 1 : 0;
    if (others == 0) return 'You joining in prayer';
    return 'You and $others others joining in prayer';
  }
  return '$prayedCount joining in prayer';
}

class JoiningPrayerText extends StatelessWidget {
  const JoiningPrayerText({
    super.key,
    required this.prayedCount,
    required this.hasCurrentUserPrayed,
    required this.isRequester,
    this.onJoin,
  });

  final int prayedCount;
  final bool hasCurrentUserPrayed;
  final bool isRequester;
  final Future<void> Function()? onJoin;

  @override
  Widget build(BuildContext context) {
    final text = joiningPrayerText(
      prayedCount: prayedCount,
      hasCurrentUserPrayed: hasCurrentUserPrayed,
      isRequester: isRequester,
    );
    final canJoin = onJoin != null;
    if (text == null) {
      if (!canJoin) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: _JoinPrayerButton(onJoin: onJoin),
      );
    }
    if (!canJoin) {
      return Text(text, style: Theme.of(context).textTheme.bodyMedium);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$text - ', style: Theme.of(context).textTheme.bodyMedium),
        _JoinPrayerButton(onJoin: onJoin),
      ],
    );
  }
}

class _JoinPrayerButton extends StatelessWidget {
  const _JoinPrayerButton({required this.onJoin});

  final Future<void> Function()? onJoin;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      onPressed: () async {
        await onJoin?.call();
      },
      child: Text(
        'Join in prayer',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}

Future<void> _confirmRemoveRequest(
  BuildContext context,
  WidgetRef ref,
  String requestId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove request?'),
      content: const Text('This will remove the request from the group feed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(prayerRequestRepositoryProvider).removeRequest(requestId);
  if (context.mounted) {
    _showMessage(context, 'The request was removed.');
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
  late final quill.QuillController _body;
  final _bodyFocusNode = FocusNode();
  final _bodyScrollController = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.request.title);
    _body = richTextControllerFromDeltaJson(
      widget.request.bodyDeltaJson.trim().isEmpty
          ? plainTextToRichTextDeltaJson(widget.request.body)
          : widget.request.bodyDeltaJson,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _bodyFocusNode.dispose();
    _bodyScrollController.dispose();
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
          Text('Request', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          RichTextFormatToolbar(
            controller: _body,
            focusNode: _bodyFocusNode,
            busy: _busy,
          ),
          const SizedBox(height: 8),
          ManuscriptCard(
            padding: const EdgeInsets.all(12),
            innerBorder: true,
            child: RichTextContentEditor(
              controller: _body,
              focusNode: _bodyFocusNode,
              scrollController: _bodyScrollController,
              minHeight: 80,
              maxHeight: 160,
            ),
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
      final bodyDeltaJson = richTextControllerToDeltaJson(_body);
      await ref
          .read(prayerRequestRepositoryProvider)
          .updateRequest(
            group: widget.group,
            request: widget.request,
            title: _title.text,
            body: plainTextFromRichTextDeltaJson(bodyDeltaJson),
            bodyDeltaJson: bodyDeltaJson,
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
    return ManuscriptCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RubricText('Care notes'),
          const SizedBox(height: 6),
          Text('Group care', style: Theme.of(context).textTheme.titleLarge),
          const IlluminatedDivider(compact: true),
          if (isLeader) ...[
            Text(
              'Join requests and reports are handled in Group Settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            Text(
              'Group members and invitations are managed in Group Settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({
    super.key,
    required this.group,
    required this.isLeader,
  });

  final VesperGroup group;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(groupRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Group Settings')),
      body: StreamBuilder<List<GroupMembership>>(
        stream: repository.watchMembers(group.id),
        builder: (context, membersSnapshot) {
          final members = membersSnapshot.data ?? const <GroupMembership>[];
          if (!isLeader) {
            return GroupSettingsContent(
              group: group,
              isLeader: false,
              members: members,
              joinRequests: const <JoinRequest>[],
              reports: const <RequestReport>[],
              pendingChanges:
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
              onInvite: () => _createAndCopyInvite(context, repository, group),
            );
          }
          return StreamBuilder<List<JoinRequest>>(
            stream: repository.watchJoinRequests(group.id),
            builder: (context, joinSnapshot) {
              return StreamBuilder<List<RequestReport>>(
                stream: ref
                    .watch(prayerRequestRepositoryProvider)
                    .watchRequestReports(group.id),
                builder: (context, reportSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: repository.watchSettingsChanges(group.id),
                    builder: (context, changesSnapshot) {
                      return GroupSettingsContent(
                        group: group,
                        isLeader: true,
                        members: members,
                        joinRequests:
                            joinSnapshot.data ?? const <JoinRequest>[],
                        reports: reportSnapshot.data ?? const <RequestReport>[],
                        pendingChanges:
                            changesSnapshot.data?.docs ??
                            const <
                              QueryDocumentSnapshot<Map<String, dynamic>>
                            >[],
                        onInvite: () =>
                            _createAndCopyInvite(context, repository, group),
                        onApproveJoinRequest: repository.approveJoinRequest,
                        onRejectJoinRequest: repository.rejectJoinRequest,
                        onPromoteMember: (member) async {
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
                        onRemoveMember: (member) async {
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
                        onDismissReport: (report) => ref
                            .read(prayerRequestRepositoryProvider)
                            .dismissRequestReport(report.id),
                        onRemoveReport: ref
                            .read(prayerRequestRepositoryProvider)
                            .removeReportedRequest,
                        onApproveSettingsChange:
                            repository.approveSettingsChange,
                        onDisputeSettingsChange:
                            repository.disputeSettingsChange,
                        onApplyReadyChanges: () =>
                            repository.maybeFinalizeSettingsChanges(group.id),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _createAndCopyInvite(
  BuildContext context,
  GroupRepository repository,
  VesperGroup group,
) async {
  final invite = await repository.createInviteCode(group.id);
  if (context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InviteMemberSheet(
        inviteCode: invite.code,
        expiresAt: invite.expiresAt,
      ),
    );
  }
}

class InviteMemberSheet extends StatelessWidget {
  const InviteMemberSheet({
    super.key,
    required this.inviteCode,
    required this.expiresAt,
    this.onCopy,
  });

  final String inviteCode;
  final DateTime expiresAt;
  final Future<void> Function()? onCopy;

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
            'Invite a New Member',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask them to scan this code or enter it from their home screen.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Center(
            child: QrImageView(
              key: const Key('invite-qr-code'),
              data: inviteCode,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  inviteCode,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Copy invite code',
                onPressed: () async {
                  final copy = onCopy;
                  if (copy == null) {
                    await Clipboard.setData(ClipboardData(text: inviteCode));
                  } else {
                    await copy();
                  }
                  if (context.mounted) {
                    _showMessage(context, 'Invite code copied.');
                  }
                },
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This code expires ${DateFormat.MMMd().format(expiresAt)}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

typedef InviteQrScannerBuilder = Widget Function(ValueChanged<String> onScan);

String? inviteCodeFromQrPayload(String payload) {
  final value = payload.trim();
  if (RegExp(r'^VESPER-[2-9A-HJ-NP-Z]{4,8}$').hasMatch(value)) return value;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'vesper' || uri.host != 'invite') {
    return null;
  }
  final code = uri.queryParameters['code']?.trim().toUpperCase();
  if (code == null || !RegExp(r'^VESPER-[2-9A-HJ-NP-Z]{4,8}$').hasMatch(code)) {
    return null;
  }
  return code;
}

class InviteQrScanner extends StatefulWidget {
  const InviteQrScanner({super.key, required this.onRequestJoin, this.scanner});

  final Future<void> Function(String code) onRequestJoin;
  final InviteQrScannerBuilder? scanner;

  @override
  State<InviteQrScanner> createState() => _InviteQrScannerState();
}

class _InviteQrScannerState extends State<InviteQrScanner> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Invite QR Code',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Point your camera at the invite QR code.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  widget.scanner?.call(_handleScan) ??
                  MobileScanner(
                    onDetect: (capture) {
                      final value = capture.barcodes
                          .map((barcode) => barcode.rawValue)
                          .whereType<String>()
                          .firstOrNull;
                      if (value != null) _handleScan(value);
                    },
                  ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String payload) async {
    if (_busy) return;
    final code = inviteCodeFromQrPayload(payload);
    if (code == null) {
      _showMessage(context, 'That invite code could not be used.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onRequestJoin(code);
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      if (mounted) {
        _showMessage(context, 'That invite code could not be used.');
        setState(() => _busy = false);
      }
    }
  }
}

class GroupSettingsContent extends StatelessWidget {
  const GroupSettingsContent({
    super.key,
    required this.group,
    required this.isLeader,
    required this.members,
    required this.joinRequests,
    required this.reports,
    required this.pendingChanges,
    required this.onInvite,
    this.onApproveJoinRequest,
    this.onRejectJoinRequest,
    this.onPromoteMember,
    this.onRemoveMember,
    this.onDismissReport,
    this.onRemoveReport,
    this.onApproveSettingsChange,
    this.onDisputeSettingsChange,
    this.onApplyReadyChanges,
  });

  final VesperGroup group;
  final bool isLeader;
  final List<GroupMembership> members;
  final List<JoinRequest> joinRequests;
  final List<RequestReport> reports;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingChanges;
  final Future<void> Function() onInvite;
  final void Function(JoinRequest request)? onApproveJoinRequest;
  final void Function(JoinRequest request)? onRejectJoinRequest;
  final Future<void> Function(GroupMembership member)? onPromoteMember;
  final Future<void> Function(GroupMembership member)? onRemoveMember;
  final void Function(RequestReport report)? onDismissReport;
  final void Function(RequestReport report)? onRemoveReport;
  final void Function(String changeId)? onApproveSettingsChange;
  final void Function(String changeId)? onDisputeSettingsChange;
  final VoidCallback? onApplyReadyChanges;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MemberSettingsContent(
          group: group,
          isLeader: isLeader,
          members: members,
          joinRequests: joinRequests,
          onInvite: onInvite,
          onApproveJoinRequest: onApproveJoinRequest,
          onRejectJoinRequest: onRejectJoinRequest,
          onPromoteMember: onPromoteMember,
          onRemoveMember: onRemoveMember,
        ),
        if (isLeader) ...[
          const SizedBox(height: 16),
          RequestReportSettingsSection(
            reports: reports,
            onDismiss: onDismissReport ?? (_) {},
            onRemove: onRemoveReport ?? (_) {},
          ),
          const SizedBox(height: 16),
          SettingsChangeSettingsSection(
            docs: pendingChanges,
            onApprove: onApproveSettingsChange ?? (_) {},
            onDispute: onDisputeSettingsChange ?? (_) {},
            onApplyReadyChanges: onApplyReadyChanges ?? () {},
          ),
        ],
      ],
    );
  }
}

class JoinRequestSettingsSection extends StatelessWidget {
  const JoinRequestSettingsSection({
    super.key,
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  final List<JoinRequest> requests;
  final void Function(JoinRequest request) onApprove;
  final void Function(JoinRequest request) onReject;

  @override
  Widget build(BuildContext context) {
    return ManuscriptCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RubricText('Leaders'),
          const SizedBox(height: 6),
          Text('Join requests', style: Theme.of(context).textTheme.titleLarge),
          const IlluminatedDivider(compact: true),
          if (requests.isEmpty)
            Text(
              'No one is waiting to join.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                    onPressed: () => onApprove(request),
                    icon: const Icon(Icons.check),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => onReject(request),
                    icon: const Icon(Icons.close),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RequestReportSettingsSection extends StatelessWidget {
  const RequestReportSettingsSection({
    super.key,
    required this.reports,
    required this.onDismiss,
    required this.onRemove,
  });

  final List<RequestReport> reports;
  final void Function(RequestReport report) onDismiss;
  final void Function(RequestReport report) onRemove;

  @override
  Widget build(BuildContext context) {
    return ManuscriptCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RubricText('Care review'),
          const SizedBox(height: 6),
          Text(
            'Reported requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const IlluminatedDivider(compact: true),
          if (reports.isEmpty)
            Text(
              'No requests have been reported.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final report in reports)
            ListTile(
              title: ProfileNameText(
                userId: report.reportedBy,
                prefix: 'Reported by ',
              ),
              subtitle: Text(
                'Request reported ${DateFormat.MMMd().format(report.createdAt)}',
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => onDismiss(report),
                    child: const Text('Dismiss'),
                  ),
                  OutlinedButton(
                    onPressed: () => onRemove(report),
                    child: const Text('Remove request'),
                  ),
                ],
              ),
            ),
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
    return ManuscriptCard(
      child: StreamBuilder<List<GroupMembership>>(
        stream: repository.watchMembers(group.id),
        builder: (context, snapshot) {
          final members = snapshot.data ?? const <GroupMembership>[];
          return MemberSettingsList(
            group: group,
            isLeader: true,
            members: members,
            joinRequests: const <JoinRequest>[],
            onInvite: () => _createAndCopyInvite(context, repository, group),
            onPromoteMember: (member) async {
              await repository.proposeLeaderAddition(group.id, member.userId);
              if (context.mounted) {
                _showMessage(context, 'Promotion proposed for Leader review.');
              }
            },
            onRemoveMember: (member) async {
              await repository.proposeMemberRemoval(group.id, member.userId);
              if (context.mounted) {
                _showMessage(context, 'Removal proposed for Leader review.');
              }
            },
          );
        },
      ),
    );
  }
}

class MemberSettingsContent extends StatelessWidget {
  const MemberSettingsContent({
    super.key,
    required this.group,
    required this.isLeader,
    required this.members,
    required this.joinRequests,
    required this.onInvite,
    this.onApproveJoinRequest,
    this.onRejectJoinRequest,
    this.onPromoteMember,
    this.onRemoveMember,
  });

  final VesperGroup group;
  final bool isLeader;
  final List<GroupMembership> members;
  final List<JoinRequest> joinRequests;
  final Future<void> Function() onInvite;
  final void Function(JoinRequest request)? onApproveJoinRequest;
  final void Function(JoinRequest request)? onRejectJoinRequest;
  final Future<void> Function(GroupMembership member)? onPromoteMember;
  final Future<void> Function(GroupMembership member)? onRemoveMember;

  @override
  Widget build(BuildContext context) {
    return ManuscriptCard(
      child: MemberSettingsList(
        group: group,
        isLeader: isLeader,
        members: members,
        joinRequests: isLeader ? joinRequests : const <JoinRequest>[],
        onInvite: onInvite,
        onApproveJoinRequest: onApproveJoinRequest,
        onRejectJoinRequest: onRejectJoinRequest,
        onPromoteMember: isLeader ? onPromoteMember : null,
        onRemoveMember: isLeader ? onRemoveMember : null,
      ),
    );
  }
}

class MemberSettingsList extends StatelessWidget {
  const MemberSettingsList({
    super.key,
    required this.group,
    required this.isLeader,
    required this.members,
    required this.joinRequests,
    required this.onInvite,
    this.onApproveJoinRequest,
    this.onRejectJoinRequest,
    this.onPromoteMember,
    this.onRemoveMember,
  });

  final VesperGroup group;
  final bool isLeader;
  final List<GroupMembership> members;
  final List<JoinRequest> joinRequests;
  final Future<void> Function() onInvite;
  final void Function(JoinRequest request)? onApproveJoinRequest;
  final void Function(JoinRequest request)? onRejectJoinRequest;
  final Future<void> Function(GroupMembership member)? onPromoteMember;
  final Future<void> Function(GroupMembership member)? onRemoveMember;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RubricText('Group book'),
        const SizedBox(height: 6),
        Text('Members', style: Theme.of(context).textTheme.titleLarge),
        const IlluminatedDivider(compact: true),
        for (final member in members)
          isLeader && member.role == 'member'
              ? MemberEntryMenu(
                  onPromote: () => onPromoteMember?.call(member),
                  onRemove: () => onRemoveMember?.call(member),
                  child: ListTile(
                    title: ProfileNameText(userId: member.userId),
                    subtitle: const Text('Member'),
                  ),
                )
              : ListTile(
                  title: ProfileNameText(userId: member.userId),
                  subtitle: Text(member.role == 'leader' ? 'Leader' : 'Member'),
                ),
        if (isLeader)
          for (final request in joinRequests)
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
                    onPressed: () => onApproveJoinRequest?.call(request),
                    icon: const Icon(Icons.check),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => onRejectJoinRequest?.call(request),
                    icon: const Icon(Icons.close),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
        ListTile(
          leading: const Icon(Icons.person_add_alt_1_outlined),
          title: const Text('Invite a New Member'),
          onTap: onInvite,
        ),
      ],
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
        return SettingsChangeSettingsSection(
          docs: docs,
          onApprove: repository.approveSettingsChange,
          onDispute: repository.disputeSettingsChange,
          onApplyReadyChanges: () =>
              repository.maybeFinalizeSettingsChanges(group.id),
        );
      },
    );
  }
}

class SettingsChangeSettingsSection extends StatelessWidget {
  const SettingsChangeSettingsSection({
    super.key,
    required this.docs,
    required this.onApprove,
    required this.onDispute,
    required this.onApplyReadyChanges,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final void Function(String changeId) onApprove;
  final void Function(String changeId) onDispute;
  final VoidCallback onApplyReadyChanges;

  @override
  Widget build(BuildContext context) {
    return ManuscriptCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RubricText('Leader review'),
          const SizedBox(height: 6),
          Text(
            'Pending changes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const IlluminatedDivider(compact: true),
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
                    onPressed: () => onApprove(doc.id),
                    icon: const Icon(Icons.check),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => onDispute(doc.id),
                    icon: const Icon(Icons.block),
                    tooltip: 'Dispute',
                  ),
                ],
              ),
            ),
          OutlinedButton(
            onPressed: onApplyReadyChanges,
            child: const Text('Apply ready changes'),
          ),
        ],
      ),
    );
  }
}

class SettingsChangeTitle extends ConsumerWidget {
  const SettingsChangeTitle({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      stream: ref.watch(prayerRequestRepositoryProvider).watchRequests(group),
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
          ManuscriptCard(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
    return ManuscriptCard(
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
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ManuscriptCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IlluminatedDivider(compact: true),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
