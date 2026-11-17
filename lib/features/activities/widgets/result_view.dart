import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/badge_catalog.dart';
import '../../../data/models/level_completion.dart';

class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.stars,
    required this.xp,
    required this.coins,
    required this.completion,
    required this.saving,
    required this.saveFailed,
    required this.onContinue,
    required this.onReplay,
    required this.onRetry,
  });

  final int stars;
  final int xp;
  final int coins;
  final LevelCompletion? completion;
  final bool saving;
  final bool saveFailed;
  final VoidCallback onContinue;
  final VoidCallback onReplay;
  final VoidCallback onRetry;

  String get _message => switch (stars) {
        3 => 'Perfect! You are a star!',
        2 => 'Great work!',
        _ => 'Well done! Try again for more stars.',
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = completion;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padLarge),
      child: Column(
        children: [
          const Spacer(),
          Text('Level complete!',
              style: text.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.padLarge),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 1; s <= 3; s++)
                  Icon(
                    s <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 72,
                    color: s <= stars
                        ? AppColors.sunshine
                        : const Color(0xFFCFC8B8),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.pad),
          Text(_message, style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.padLarge),
          if (saving)
            const CircularProgressIndicator()
          else if (saveFailed) ...[
            Text('Could not save your progress.',
                style: text.bodyMedium, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Try saving again')),
          ] else if (done != null)
            _Rewards(completion: done, xp: xp, coins: coins),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : onContinue,
              child: const Text('Continue'),
            ),
          ),
          if (stars < 3) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: saving ? null : onReplay,
                child: const Text('Play again'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Rewards extends StatelessWidget {
  const _Rewards({
    required this.completion,
    required this.xp,
    required this.coins,
  });

  final LevelCompletion completion;
  final int xp;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badges = [
      for (final id in completion.newBadges)
        if (BadgeCatalog.byId(id) != null) BadgeCatalog.byId(id)!,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (completion.firstTime)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _Pill('⭐ +$xp XP', AppColors.sunshine),
              _Pill('🪙 +$coins', AppColors.sunshine),
            ],
          )
        else
          Text('Nice replay!', style: text.bodyLarge),
        if (completion.dailyBonus > 0) ...[
          const SizedBox(height: 12),
          _Pill(
            '🔥 Day ${completion.streak} streak! +${completion.dailyBonus} bonus 🪙',
            AppColors.orange.withValues(alpha: 0.35),
          ),
        ] else if (completion.streak > 1) ...[
          const SizedBox(height: 12),
          Text('🔥 ${completion.streak} day streak', style: text.bodyMedium),
        ],
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final b in badges)
                _Pill('${b.emoji} New badge: ${b.title}', AppColors.green),
            ],
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
