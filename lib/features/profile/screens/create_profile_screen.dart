import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_limits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_badge.dart';
import '../../../data/models/avatar_catalog.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();

  String _avatarId = AvatarCatalog.all.first.id;
  int _age = 9;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(childRepositoryProvider).addChild(
            uid,
            nickname: _nickname.text.trim(),
            avatarId: _avatarId,
            age: _age,
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save. Check your internet and try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New player')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pick your hero', style: text.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final a in AvatarCatalog.all)
                      GestureDetector(
                        onTap: () => setState(() => _avatarId = a.id),
                        child: AvatarBadge(
                          avatarId: a.id,
                          size: 64,
                          selected: a.id == _avatarId,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Your nickname', style: text.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nickname,
                  maxLength: AppLimits.nicknameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'Not your real name!'),
                  validator: (v) =>
                      (v == null || v.trim().length < AppLimits.nicknameMinLength)
                          ? 'At least ${AppLimits.nicknameMinLength} letters'
                          : null,
                ),
                const SizedBox(height: 8),
                Text('How old are you?', style: text.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var age = AppLimits.minAge;
                        age <= AppLimits.maxAge;
                        age++)
                      ChoiceChip(
                        label: Text('$age'),
                        selected: _age == age,
                        selectedColor: AppColors.sunshine,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _age = age),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.tryAgain),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: text.bodyMedium)),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _create,
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Let's go!"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
