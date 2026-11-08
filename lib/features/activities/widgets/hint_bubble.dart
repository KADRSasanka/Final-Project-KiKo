import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HintBubble extends StatelessWidget {
  const HintBubble({super.key, required this.hint});

  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: hint == null
          ? const SizedBox.shrink(key: ValueKey('no-hint'))
          : Container(
              key: ValueKey(hint),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0BF),
                border: Border.all(color: AppColors.sunshine, width: 2),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
