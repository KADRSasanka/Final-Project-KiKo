import 'package:flutter/material.dart';

/// Shown when a child tries to start a level after today's limit is reached.
Future<void> showTimeUpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Time's up for today! 🌙"),
      content: const Text(
        'Great playing! Come back tomorrow.\n\n'
        'A grown-up can change the time limit in the Grown-ups tab.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
