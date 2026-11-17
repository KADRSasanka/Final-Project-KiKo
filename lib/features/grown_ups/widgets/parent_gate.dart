import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_providers.dart';

/// Asks for the grown-up's account password. Returns true if it was correct.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _ParentGateDialog(),
  );
  return ok ?? false;
}

class _ParentGateDialog extends ConsumerStatefulWidget {
  const _ParentGateDialog();

  @override
  ConsumerState<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends ConsumerState<_ParentGateDialog> {
  final _password = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  String _message(Object e) {
    if (e is FirebaseAuthException &&
        const {'wrong-password', 'invalid-credential', 'invalid-login-credentials'}
            .contains(e.code)) {
      return 'That password is not right.';
    }
    return AuthRepository.friendlyError(e);
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).confirmPassword(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _message(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grown-ups only 🔒'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your account password to continue.'),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _hide,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_hide
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Text('Unlock'),
        ),
      ],
    );
  }
}
