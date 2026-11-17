import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/models/shop_catalog.dart';
import '../../../data/repositories/shop_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/shop_providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final child = ref.watch(activeChildProvider);

    if (child == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sunshine,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Text('🪙 ${child.coins}', style: text.titleSmall),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pad),
        children: [
          Center(child: AvatarBadge.forChild(child, size: 110)),
          const SizedBox(height: 4),
          Center(child: Text(child.nickname, style: text.titleMedium)),
          const SizedBox(height: AppSizes.padLarge),
          _Section(
            title: 'Hats',
            slot: ShopCatalog.hatSlot,
            child: child,
          ),
          const SizedBox(height: AppSizes.padLarge),
          _Section(
            title: 'Backgrounds',
            slot: ShopCatalog.backgroundSlot,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.title, required this.slot, required this.child});

  final String title;
  final String slot;
  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: [
            for (final item in ShopCatalog.inSlot(slot))
              _ItemTile(
                item: item,
                owned: child.ownedItems.contains(item.id),
                equipped: child.equipped[item.slot] == item.id,
                canAfford: child.coins >= item.price,
                onTap: () => _onTap(context, ref, child, item),
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _onTap(
  BuildContext context,
  WidgetRef ref,
  ChildProfile child,
  ShopItem item,
) async {
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return;

  final repo = ref.read(shopRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final owned = child.ownedItems.contains(item.id);

  try {
    // Already owned: tap to wear it, tap again to take it off.
    if (owned) {
      final wearing = child.equipped[item.slot] == item.id;
      await repo.equip(
        uid: uid,
        childId: child.id,
        slot: item.slot,
        itemId: wearing ? null : item.id,
      );
      return;
    }

    if (child.coins < item.price) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Earn ${item.price - child.coins} more coins by playing! 🪙',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${item.name}?'),
        content: Text('It costs ${item.price} 🪙'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await repo.buy(uid: uid, childId: child.id, itemId: item.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          PurchaseResult.success => 'You got the ${item.name}! 🎉',
          PurchaseResult.notEnoughCoins => 'Not enough coins yet.',
          PurchaseResult.alreadyOwned => 'You already have this!',
          PurchaseResult.notFound => 'Item not found.',
        }),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Something went wrong. Try again.')),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.onTap,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dim = !owned && !canAfford;

    final String status;
    if (equipped) {
      status = '✅ Wearing';
    } else if (owned) {
      status = 'Owned';
    } else {
      status = '🪙 ${item.price}';
    }

    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          side: BorderSide(
            color: equipped ? AppColors.success : Colors.transparent,
            width: 3,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Preview(item: item),
                const SizedBox(height: 6),
                Text(item.name,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(status, style: text.titleSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    if (item.emoji.isNotEmpty) {
      return Text(item.emoji, style: const TextStyle(fontSize: 40));
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: item.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}
