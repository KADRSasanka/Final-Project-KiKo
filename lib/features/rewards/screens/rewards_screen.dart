import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/badge_catalog.dart';
import '../../../data/models/child_profile.dart';
import '../../profile/providers/profile_providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final child = ref.watch(activeChildProvider);

    if (child == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rewards')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final earned = child.badges.toSet();
    final earnedCount =
        BadgeCatalog.all.where((b) => earned.contains(b.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pad),
        children: [
          _StreakCard(child: child),
          const SizedBox(height: AppSizes.pad),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(label: '⭐ ${child.xp} XP'),
              _StatChip(label: '🪙 ${child.coins} coins'),
            ],
          ),
          const SizedBox(height: AppSizes.padLarge),
          Text('Badges ($earnedCount of ${BadgeCatalog.all.length})',
              style: text.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              for (final b in BadgeCatalog.all)
                _BadgeTile(badge: b, earned: earned.contains(b.id)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final days = child.currentStreak;

    final String message;
    if (days == 0) {
      message = 'Play a level today to start your streak!';
    } else if (child.playedToday) {
      message = 'You played today. Come back tomorrow!';
    } else {
      message = 'Play today to keep your streak going!';
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.padLarge),
      decoration: BoxDecoration(
        color: AppColors.sunshine.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 56)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(days == 1 ? '1 day streak' : '$days day streak',
                    style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(message, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earned});

  final BadgeInfo badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: earned ? AppColors.surface : const Color(0xFFEFE9DA),
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${badge.emoji} ${badge.title}'),
            content: Text(
              earned
                  ? 'You earned this badge! ${badge.description}'
                  : 'How to earn: ${badge.description}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: earned ? 1 : 0.25,
                child: Text(badge.emoji, style: const TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  earned ? badge.title : '🔒 ${badge.title}',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
