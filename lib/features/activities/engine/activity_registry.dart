import 'package:flutter/widgets.dart';

import '../../../data/models/level.dart';
import '../fraction_pizza/fraction_pizza_activity.dart';
import '../quiz/quiz_activity.dart';
import '../sorting/sorting_activity.dart';
import 'activity_session.dart';
import 'coming_soon_activity.dart';

typedef ActivityBuilder = Widget Function(
  Level level,
  ActivitySession session,
);

/// Maps the "activity" string in the level JSON to a widget.
/// To add a new activity type: build the widget, then add one line here.
class ActivityRegistry {
  ActivityRegistry._();

  static final Map<String, ActivityBuilder> _builders = {
    'quiz': (level, session) => QuizActivity(level: level, session: session),
    'sorting': (level, session) => SortingActivity(level: level, session: session),
    'fraction_pizza': (level, session) =>
        FractionPizzaActivity(level: level, session: session),
  };

  static Widget build(Level level, ActivitySession session) {
    final builder = _builders[level.activity];
    if (builder == null) {
      return ComingSoonActivity(level: level, session: session);
    }
    return builder(level, session);
  }
}
