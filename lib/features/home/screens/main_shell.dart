import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../grown_ups/providers/grown_ups_providers.dart';

/// Bottom navigation: Play / Rewards / Shop / Grown-ups.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _grownUpsIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) {
          // Leaving the Grown-ups tab locks it again.
          if (navigationShell.currentIndex == _grownUpsIndex &&
              i != _grownUpsIndex) {
            ref.read(grownUpUnlockedUntilProvider.notifier).state = null;
          }
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Play',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Grown-ups',
          ),
        ],
      ),
    );
  }
}
