import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_limits.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../../data/models/child_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final players = ref.watch(childrenProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padLarge),
          child: Column(
            children: [
              Text("Who's playing?",
                  style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.pad),
              Expanded(
                child: players.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load players.\nCheck your internet.',
                      style: text.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (list) => _PlayerGrid(list),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(activeChildIdProvider.notifier).state = null;
                  ref.read(authRepositoryProvider).signOut();
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerGrid extends ConsumerWidget {
  const _PlayerGrid(this.players);

  final List<ChildProfile> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSizes.pad,
      crossAxisSpacing: AppSizes.pad,
      childAspectRatio: 0.95,
      children: [
        for (final p in players)
          _PlayerCard(
            player: p,
            onTap: () {
              ref.read(activeChildIdProvider.notifier).state = p.id;
              context.go(AppRoutes.home);
            },
          ),
        if (players.length < AppLimits.maxChildren)
          _AddCard(onTap: () => context.push(AppRoutes.createProfile)),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.onTap});

  final ChildProfile player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AvatarBadge(avatarId: player.avatarId, size: 84),
              const SizedBox(height: 8),
              Text(
                player.nickname,
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, size: 64, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('Add player', style: text.titleMedium),
          ],
        ),
      ),
    );
  }
}
