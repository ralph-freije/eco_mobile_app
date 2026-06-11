import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final message = await ApiClient.instance
          .forgotPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _message = message;
          _isSuccess = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = ApiClient.errorMessage(error);
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Reset password',
              subtitle: 'Enter your email and we will send a reset link.',
            ),
            const SizedBox(height: 26),
            if (_message != null) ...[
              AuthMessage(message: _message!, isSuccess: _isSuccess),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Enter your email address.';
                if (!email.contains('@')) return 'Enter a valid email address.';
                return null;
              },
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Send reset link',
              isLoading: _isLoading,
              onPressed: _submit,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
