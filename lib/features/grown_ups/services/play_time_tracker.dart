import 'dart:async';

import 'package:flutter/widgets.dart';

/// Counts the seconds a child spends playing (app in the foreground) and
/// saves them in small batches.
class PlayTimeTracker with WidgetsBindingObserver {
  PlayTimeTracker({required this.onFlush, this.flushEvery = 30});

  final Future<void> Function(int seconds) onFlush;
  final int flushEvery;

  Timer? _ticker;
  int _pending = 0;
  bool _foreground = true;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_foreground) return;
      _pending++;
      if (_pending >= flushEvery) _flush();
    });
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    WidgetsBinding.instance.removeObserver(this);
    _flush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _flush();
  }

  void _flush() {
    final seconds = _pending;
    if (seconds <= 0) return;
    _pending = 0;
    onFlush(seconds).catchError((_) {});
  }
}
