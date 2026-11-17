import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/avatar_catalog.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/models/track_progress.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../providers/grown_ups_providers.dart';
import '../widgets/parent_gate.dart';

const _limitOptions = [0, 15, 30, 45, 60, 90];

String _formatSeconds(int seconds) {
  if (seconds <= 0) return '0 min';
  if (seconds < 60) return '<1 min';
  return '${seconds ~/ 60} min';
}

class GrownUpsScreen extends ConsumerStatefulWidget {
  const GrownUpsScreen({super.key});

  @override
  ConsumerState<GrownUpsScreen> createState() => _GrownUpsScreenState();
}

class _GrownUpsScreenState extends ConsumerState<GrownUpsScreen> {
  static const _unlockFor = Duration(minutes: 3);

  String? _selectedId;
  Timer? _relockTimer;

  @override
  void dispose() {
    _relockTimer?.cancel();
    super.dispose();
  }

  Future<void> _unlock() async {
    final ok = await showParentGate(context);
    if (!ok || !mounted) return;
    ref.read(grownUpUnlockedUntilProvider.notifier).state =
        DateTime.now().add(_unlockFor);
    // Re-lock automatically if the grown-up walks away.
    _relockTimer?.cancel();
    _relockTimer = Timer(_unlockFor, () {
      if (mounted) setState(() {});
    });
  }

  void _lock() =>
      ref.read(grownUpUnlockedUntilProvider.notifier).state = null;

  Future<void> _setLimit(ChildProfile child, int minutes) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(grownUpsRepositoryProvider).setDailyLimit(
            uid: uid,
            childId: child.id,
            minutes: minutes,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Check your internet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final until = ref.watch(grownUpUnlockedUntilProvider);
    final unlocked = until != null && DateTime.now().isBefore(until);

    if (!unlocked) return _LockedView(onUnlock: _unlock);

    final children = ref.watch(childrenProvider).valueOrNull ?? const [];
    if (children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grown-ups')),
        body: const Center(child: Text('No players yet.')),
      );
    }

    final activeId = ref.watch(activeChildIdProvider);
    final selected = children.firstWhere(
      (c) => c.id == (_selectedId ?? activeId),
      orElse: () => children.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grown-ups'),
        actions: [
          IconButton(
            tooltip: 'Lock now',
            icon: const Icon(Icons.lock_outline),
            onPressed: _lock,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pad),
        children: [
          _ChildPicker(
            children: children,
            selectedId: selected.id,
            onSelect: (id) => setState(() => _selectedId = id),
          ),
          const SizedBox(height: AppSizes.padLarge),
          _Summary(child: selected),
          const SizedBox(height: AppSizes.padLarge),
          _SectionTitle('Last 7 days'),
          const SizedBox(height: 12),
          _WeekChart(child: selected),
          const SizedBox(height: AppSizes.padLarge),
          _SectionTitle('Progress by track'),
          const SizedBox(height: 12),
          _TrackProgressList(childId: selected.id),
          const SizedBox(height: AppSizes.padLarge),
          _SectionTitle('Daily time limit'),
          const SizedBox(height: 12),
          _LimitPicker(
            child: selected,
            onChanged: (m) => _setLimit(selected, m),
          ),
        ],
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🔒',
                style: TextStyle(fontSize: 72), textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.pad),
            Text('Grown-ups only',
                style: text.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'See progress and set time limits.\n'
              'Your account password is needed.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.padLarge),
            ElevatedButton(onPressed: onUnlock, child: const Text('Unlock')),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _ChildPicker extends StatelessWidget {
  const _ChildPicker({
    required this.children,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ChildProfile> children;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in children)
          ChoiceChip(
            avatar: Text(AvatarCatalog.byId(c.avatarId).emoji),
            label: Text(c.nickname),
            selected: c.id == selectedId,
            selectedColor: AppColors.sunshine,
            showCheckmark: false,
            onSelected: (_) => onSelect(c.id),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final limit = child.hasLimit ? ' of ${child.dailyLimitMinutes}' : '';
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            emoji: '⏱',
            value: '${_formatSeconds(child.playedTodaySeconds)}$limit',
            label: 'Today',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(emoji: '⭐', value: '${child.xp}', label: 'XP'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            emoji: '🔥',
            value: '${child.currentStreak}',
            label: 'Day streak',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: text.titleMedium),
            ),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.child});

  final ChildProfile child;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final values = [for (final d in days) child.secondsOn(d)];
    final maxValue = max(values.fold<int>(0, max), 60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pad),
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${values[i] ~/ 60}', style: text.bodySmall),
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: max(4.0, 70.0 * values[i] / maxValue),
                        decoration: BoxDecoration(
                          color: i == days.length - 1
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_letters[days[i].weekday - 1],
                          style: text.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackProgressList extends ConsumerWidget {
  const _TrackProgressList({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(allProgressProvider(childId)).valueOrNull ??
        const <String, TrackProgress>{};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pad),
        child: Column(
          children: [
            for (final track in Track.values) ...[
              _TrackRow(
                label: track.label,
                color: track.color,
                done: progress[track.name]?.stars.length ?? 0,
                total: ref.watch(levelsProvider(track.name)).valueOrNull?.length ?? 5,
                stars: (progress[track.name]?.stars.values ?? const <int>[])
                    .fold<int>(0, (a, b) => a + b),
                textTheme: text,
              ),
              if (track != Track.values.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.label,
    required this.color,
    required this.done,
    required this.total,
    required this.stars,
    required this.textTheme,
  });

  final String label;
  final Color color;
  final int done;
  final int total;
  final int stars;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final shown = min(done, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 8, backgroundColor: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: textTheme.titleSmall)),
            Text('$shown/$total levels  ⭐ $stars', style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : shown / total,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

class _LimitPicker extends StatelessWidget {
  const _LimitPicker({required this.child, required this.onChanged});

  final ChildProfile child;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in _limitOptions)
              ChoiceChip(
                label: Text(m == 0 ? 'No limit' : '$m min'),
                selected: child.dailyLimitMinutes == m,
                selectedColor: AppColors.sunshine,
                showCheckmark: false,
                onSelected: (_) => onChanged(m),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          child.hasLimit
              ? 'When time is up, ${child.nickname} can finish the level in '
                  'progress. New levels open again tomorrow.'
              : 'No limit set. ${child.nickname} can play any time.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
