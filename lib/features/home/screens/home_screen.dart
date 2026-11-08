import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../profile/providers/profile_providers.dart';

/// Placeholder Adventure Map: shows the active player and the 5 tracks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final child = ref.watch(activeChildProvider);

    return Scaffold(
      appBar: AppBar(
        leading: child == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(8),
                child: AvatarBadge(avatarId: child.avatarId, size: 40),
              ),
        title: Text('Hi, ${child?.nickname ?? 'there'}!'),
        actions: [
          IconButton(
            tooltip: 'Switch player',
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: () => context.go(AppRoutes.profiles),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pad),
        children: [
          Row(
            children: [
              _StatChip(label: '⭐ ${child?.xp ?? 0} XP'),
              const SizedBox(width: 12),
              _StatChip(label: '🪙 ${child?.coins ?? 0}'),
            ],
          ),
          const SizedBox(height: AppSizes.pad),
          for (final track in Track.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.pad),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSizes.pad),
                  leading:
                      CircleAvatar(radius: 26, backgroundColor: track.color),
                  title: Text(track.label, style: text.titleMedium),
                  trailing: const Icon(Icons.chevron_right),
                ),
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
        color: AppColors.sunshine,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
