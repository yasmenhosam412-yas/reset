import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_event.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCodeStep = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthResetToIdleEvent());
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (!_emailFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSendRecoveryOtpEvent(email: _emailController.text.trim()),
    );
  }

  void _sendMagicLink() {
    if (!_emailFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSendRecoveryMagicLinkEvent(email: _emailController.text.trim()),
    );
  }

  void _verifyAndReset() {
    if (!_codeFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthVerifyRecoveryOtpEvent(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text,
      ),
    );
  }

  void _backToEmailStep() {
    setState(() {
      _showCodeStep = false;
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    context.read<AuthBloc>().add(AuthResetToIdleEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.authState == AuthState.errorForgotPassword &&
              state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.authState == AuthState.recoveryOtpSent) {
            setState(() => _showCodeStep = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Enter the code from your email, then choose a new password.',
                ),
              ),
            );
          }
          if (state.authState == AuthState.recoveryMagicLinkSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Check your email and tap the reset link. It opens this app with a secure token so you can choose a new password.',
                ),
              ),
            );
          }
          if (state.authState == AuthState.loadedForgotPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password updated. Sign in with your new password.',
                ),
              ),
            );
            context.read<AuthBloc>().add(AuthResetToIdleEvent());
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state.authState == AuthState.loading;

          return Stack(
            children: [
              Positioned(
                top: -95,
                right: -55,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -40,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: !_showCodeStep
                                ? _buildEmailStep(context, isLoading)
                                : _buildCodeStep(context, isLoading),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context, bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Forgot password?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Use a one-time code in the app, or get an email with a secure reset link (opens this app to set a new password).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isLoading) _sendCode();
            },
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email is required';
              if (!email.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _sendCode,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send code'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: isLoading ? null : _sendMagicLink,
              child: const Text('Email me a reset link instead'),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: isLoading ? null : () => context.pop(),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(BuildContext context, bool isLoading) {
    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('code'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.pin_outlined, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Verify & set password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Code sent to ${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              hintText: '6–8 digit code',
              prefixIcon: Icon(Icons.password_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final code = value?.trim() ?? '';
              if (code.isEmpty) return 'Code is required';
              if (code.length < 6) return 'Code looks too short';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.isEmpty) return 'Password is required';
              if (password.length < 6) {
                return 'At least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isLoading) _verifyAndReset();
            },
            decoration: InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _verifyAndReset,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify code & update password'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : _backToEmailStep,
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
