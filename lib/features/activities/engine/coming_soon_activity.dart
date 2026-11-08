import 'package:flutter/material.dart';

import '../../../data/models/activity_info.dart';
import '../../../data/models/level.dart';
import 'activity_session.dart';

/// Used for activity types that are not built yet, so every level stays
/// playable. The test button completes the level.
class ComingSoonActivity extends StatefulWidget {
  const ComingSoonActivity({
    super.key,
    required this.level,
    required this.session,
  });

  final Level level;
  final ActivitySession session;

  @override
  State<ComingSoonActivity> createState() => _ComingSoonActivityState();
}

class _ComingSoonActivityState extends State<ComingSoonActivity> {
  @override
  void initState() {
    super.initState();
    widget.session.begin(1);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final info = ActivityInfo.of(widget.level.activity);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(info.emoji,
              style: const TextStyle(fontSize: 80), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('${info.label} is coming soon!',
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => widget.session.correct(),
            child: const Text('Finish level (test)'),
          ),
        ],
      ),
    );
  }
}
