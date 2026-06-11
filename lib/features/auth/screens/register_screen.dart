import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthController>().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      );
      if (mounted) context.go('/dashboard');
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
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
              title: 'Create account',
              subtitle: 'Start building greener habits today.',
            ),
            const SizedBox(height: 26),
            if (_error != null) ...[
              AuthMessage(message: _error!),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Your full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your full name.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Minimum 6 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter a password.';
                if (value.length < 6) return 'Use at least 6 characters.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmationController,
              obscureText: _obscureConfirmation,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                hintText: 'Repeat your password',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match.'
                  : null,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Create account',
              isLoading: _isLoading,
              onPressed: _submit,
              icon: Icons.person_add_alt_1_rounded,
            ),
            const SizedBox(height: 12),
            // TODO: Obtain a Google ID token with google_sign_in, then call
            // ApiClient.loginWithGoogleToken after Laravel implements
            // POST /api/auth/google/mobile.
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mobile Google sign-in needs a Laravel endpoint: POST /api/auth/google/mobile.',
                          ),
                        ),
                      ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
