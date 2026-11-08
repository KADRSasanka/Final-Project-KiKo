import 'package:flutter/material.dart';

import '../../data/models/avatar_catalog.dart';
import '../theme/app_theme.dart';

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatarId,
    this.size = 64,
    this.selected = false,
  });

  final String avatarId;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarCatalog.byId(avatarId);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatar.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 4,
        ),
      ),
      child: Text(avatar.emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
