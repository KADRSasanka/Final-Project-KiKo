import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/quiz_question.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestion>, String>(
  (ref, levelId) => ref.watch(contentRepositoryProvider).loadQuestions(levelId),
);

class QuizActivity extends ConsumerWidget {
  const QuizActivity({super.key, required this.level, required this.session});

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(quizQuestionsProvider(level.id));
    return questions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // No question file yet: keep the level playable.
      error: (e, _) => ComingSoonActivity(level: level, session: session),
      data: (list) => list.isEmpty
          ? ComingSoonActivity(level: level, session: session)
          : _QuizBody(questions: list, session: session),
    );
  }
}

class _Item {
  const _Item(this.prompt, this.options, this.answer, this.hints);

  final String prompt;
  final List<String> options;
  final int answer;
  final List<String> hints;
}

class _QuizBody extends StatefulWidget {
  const _QuizBody({required this.questions, required this.session});

  final List<QuizQuestion> questions;
  final ActivitySession session;

  @override
  State<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<_QuizBody> {
  late final List<_Item> _items;
  int _step = 0;
  final Set<int> _wrong = {};
  int? _correctPick;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _items = [for (final q in widget.questions) _shuffled(q, rng)];
    widget.session.begin(_items.length, hints: _items.first.hints);
  }

  // Shuffle options so the right answer is not always in the same spot.
  _Item _shuffled(QuizQuestion q, Random rng) {
    final correct = q.options[q.answer];
    final options = [...q.options]..shuffle(rng);
    return _Item(q.prompt, options, options.indexOf(correct), q.hints);
  }

  Future<void> _onTap(int i) async {
    if (_locked || _wrong.contains(i)) return;
    final item = _items[_step];

    if (i == item.answer) {
      setState(() {
        _correctPick = i;
        _locked = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final isLast = _step == _items.length - 1;
      widget.session.correct(
        nextHints: isLast ? const [] : _items[_step + 1].hints,
      );
      if (!isLast) {
        setState(() {
          _step++;
          _wrong.clear();
          _correctPick = null;
          _locked = false;
        });
      }
    } else {
      setState(() => _wrong.add(i));
      widget.session.wrong();
    }
  }

  _OptionState _stateOf(int i) {
    if (_correctPick == i) return _OptionState.correct;
    if (_wrong.contains(i)) return _OptionState.wrong;
    return _OptionState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final item = _items[_step];

    return Padding(
      padding: const EdgeInsets.all(AppSizes.padLarge),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  item.prompt,
                  style: text.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          for (var i = 0; i < item.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionButton(
                label: item.options[i],
                state: _stateOf(i),
                onTap: () => _onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

enum _OptionState { normal, correct, wrong }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    var opacity = 1.0;

    switch (state) {
      case _OptionState.correct:
        bg = AppColors.success;
        border = AppColors.success;
      case _OptionState.wrong:
        bg = const Color(0xFFFFE2B8); // soft orange, never red
        border = AppColors.tryAgain;
        opacity = 0.7;
      case _OptionState.normal:
        bg = AppColors.surface;
        border = const Color(0xFFE3DCCB);
    }

    final radius = BorderRadius.circular(AppSizes.radius);
    return Opacity(
      opacity: opacity,
      child: Material(
        color: bg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border, width: 3),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 64,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
