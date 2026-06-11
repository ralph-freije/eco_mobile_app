import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthController>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
              title: 'Welcome back',
              subtitle: 'Continue your sustainability journey.',
            ),
            const SizedBox(height: 26),
            if (_error != null) ...[
              AuthMessage(message: _error!),
              const SizedBox(height: 18),
            ],
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
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
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your password.'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Sign in',
              isLoading: _isLoading,
              onPressed: _submit,
              icon: Icons.arrow_forward_rounded,
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
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New to EcoTrack?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
