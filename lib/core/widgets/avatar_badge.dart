import 'package:flutter/material.dart';

import '../../data/models/avatar_catalog.dart';
import '../../data/models/child_profile.dart';
import '../../data/models/shop_catalog.dart';
import '../theme/app_theme.dart';

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatarId,
    this.size = 64,
    this.selected = false,
    this.hatId,
    this.backgroundId,
  });

  /// Avatar with the child's equipped hat and background.
  factory AvatarBadge.forChild(
    ChildProfile child, {
    Key? key,
    double size = 64,
    bool selected = false,
  }) {
    return AvatarBadge(
      key: key,
      avatarId: child.avatarId,
      size: size,
      selected: selected,
      hatId: child.hatId,
      backgroundId: child.backgroundId,
    );
  }

  final String avatarId;
  final double size;
  final bool selected;
  final String? hatId;
  final String? backgroundId;

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarCatalog.byId(avatarId);
    final bg = ShopCatalog.byId(backgroundId)?.color ?? avatar.color;
    final hat = ShopCatalog.byId(hatId);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 4,
              ),
            ),
            child: Text(avatar.emoji, style: TextStyle(fontSize: size * 0.5)),
          ),
          if (hat != null && hat.emoji.isNotEmpty)
            Positioned(
              top: -size * 0.18,
              child: Text(
                hat.emoji,
                style: TextStyle(fontSize: size * 0.4, height: 1),
              ),
            ),
        ],
      ),
    );
  }
}
