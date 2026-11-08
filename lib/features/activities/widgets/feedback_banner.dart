import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../engine/activity_session.dart';

/// Positive feedback. A mistake is never a red "wrong" screen.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.kind, required this.text});

  final FeedbackKind kind;
  final String text;

  @override
  Widget build(BuildContext context) {
    final success = kind == FeedbackKind.success;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: kind == FeedbackKind.none
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Container(
              key: ValueKey(text),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: success ? AppColors.success : const Color(0xFFFFE2B8),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.lightbulb_outline,
                    color: AppColors.text,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
