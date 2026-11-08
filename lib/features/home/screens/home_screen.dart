import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Placeholder Adventure Map: lists the 5 tracks using the theme colors.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Adventure Map')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.pad),
        itemCount: Track.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.pad),
        itemBuilder: (context, index) {
          final track = Track.values[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSizes.pad),
              leading: CircleAvatar(radius: 26, backgroundColor: track.color),
              title: Text(track.label, style: text.titleMedium),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
