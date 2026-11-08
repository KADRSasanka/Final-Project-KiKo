import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

enum FeedbackKind { none, success, tryAgain }

/// The contract between the play screen (host) and every activity.
///
/// An activity only needs to call three methods:
///   session.begin(steps, hints: [...])   once, when it is ready
///   session.correct(nextHints: [...])    when the child answers right
///   session.wrong()                      when the child answers wrong
///
/// The host handles everything else: progress dots, positive feedback,
/// hints, stars, saving progress and the result screen.
class ActivitySession extends ChangeNotifier {
  static const _praise = [
    'Great job! 🎉',
    'You got it! ⭐',
    'Awesome! 🌟',
    'Nice one! 👏',
    'Super! 🚀',
  ];

  static const _encourage = [
    'Almost! Try again 💪',
    'So close! Give it another go.',
    'Good try! You can do it.',
    'Keep going, you are close!',
  ];

  final _rng = Random();
  bool _disposed = false;
  Timer? _timer;

  int _totalSteps = 0;
  int _currentStep = 0;
  int _mistakes = 0;
  int _hintsUsed = 0;
  int _stepMistakes = 0;
  int _hintsShown = 0;
  List<String> _hints = const [];
  FeedbackKind _feedback = FeedbackKind.none;
  String _feedbackText = '';

  // ---- read by the host ----
  int get totalSteps => _totalSteps;
  int get currentStep => _currentStep;
  bool get finished => _totalSteps > 0 && _currentStep >= _totalSteps;
  FeedbackKind get feedback => _feedback;
  String get feedbackText => _feedbackText;
  int get hintsShown => _hintsShown;
  bool get hasMoreHints => _hintsShown < _hints.length;
  String? get currentHint => _hintsShown == 0 ? null : _hints[_hintsShown - 1];

  /// Always at least 1 star for finishing. Mistakes and hints cost stars.
  int get stars {
    final penalty = _mistakes + _hintsUsed;
    if (penalty <= 1) return 3;
    if (penalty <= 3) return 2;
    return 1;
  }

  // ---- called by activities ----

  /// Call once when the activity is ready. Safe to call from initState.
  void begin(int steps, {List<String> hints = const []}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _totalSteps = steps;
      _currentStep = 0;
      _hints = hints;
      _hintsShown = 0;
      notifyListeners();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// The current step was answered correctly.
  void correct({List<String> nextHints = const []}) {
    _currentStep++;
    _stepMistakes = 0;
    _hints = nextHints;
    _hintsShown = 0;
    _showFeedback(FeedbackKind.success, _pick(_praise));
  }

  /// A wrong attempt. No "wrong screen": just a kind message, and a free
  /// hint after the second miss on the same step.
  void wrong() {
    _mistakes++;
    _stepMistakes++;
    if (_stepMistakes >= 2 && hasMoreHints) _hintsShown++;
    _showFeedback(FeedbackKind.tryAgain, _pick(_encourage));
  }

  // ---- called by the host ----
  void useHint() {
    if (!hasMoreHints) return;
    _hintsShown++;
    _hintsUsed++;
    notifyListeners();
  }

  String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  void _showFeedback(FeedbackKind kind, String text) {
    _feedback = kind;
    _feedbackText = text;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (_disposed) return;
      _feedback = FeedbackKind.none;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
