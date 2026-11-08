import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 28 : 14,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: i < current
                  ? AppColors.success
                  : i == current
                      ? AppColors.primary
                      : const Color(0xFFE3DCCB),
            ),
          ),
      ],
    );
  }
}
