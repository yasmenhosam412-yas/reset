import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/routing/app_router.dart';
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
              SnackBar(content: Text(l10n.forgotOtpInstructionSnack)),
            );
          }
          if (state.authState == AuthState.loadedForgotPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.passwordUpdatedSnack)),
            );
            context.read<AuthBloc>().add(AuthResetToIdleEvent());
            context.go(AppRouter.loginPath);
          }
        },
        builder: (context, state) {
          final isLoading = state.authState == AuthState.loading;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer,
                  colors.secondaryContainer,
                  colors.tertiaryContainer.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        color: colors.surface,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                            color: colors.shadow.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(36),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [colors.primary, colors.secondary],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.onPrimary.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _showCodeStep
                                        ? Icons.pin_outlined
                                        : Icons.mark_email_unread_outlined,
                                    size: 28,
                                    color: colors.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showCodeStep
                                      ? l10n.forgotHeroTitleStep2
                                      : l10n.forgotHeroTitleStep1,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showCodeStep
                                      ? l10n.forgotHeroSubtitleStep2
                                      : l10n.forgotHeroSubtitleStep1,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onPrimary.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: !_showCodeStep
                                  ? _buildEmailStep(context, isLoading)
                                  : _buildCodeStep(context, isLoading),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context, bool isLoading) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotStep1Title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isLoading) _sendCode();
            },
            decoration: InputDecoration(
              labelText: l10n.emailAddress,
              hintText: l10n.emailHint,
              prefixIcon: const Icon(Icons.alternate_email),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return l10n.emailRequired;
              if (!email.contains('@')) return l10n.validEmailRequired;
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : _sendCode,
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(l10n.sendCode),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.rememberedIt,
                style: theme.textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.go(AppRouter.loginPath),
                child: Text(l10n.backToLogin),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(BuildContext context, bool isLoading) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('code'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotStep2Title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.codeSentTo(_emailController.text.trim()),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.verificationCode,
              hintText: l10n.verificationCodeHint,
              prefixIcon: const Icon(Icons.password_outlined),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              final code = value?.trim() ?? '';
              if (code.isEmpty) return l10n.codeRequired;
              if (code.length < 6) return l10n.codeTooShort;
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.newPassword,
              prefixIcon: const Icon(Icons.password_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.isEmpty) return l10n.passwordRequired;
              if (password.length < 6) {
                return l10n.atLeast6Chars;
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
              labelText: l10n.confirmPassword,
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return l10n.passwordsDoNotMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : _verifyAndReset,
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(l10n.verifyAndUpdatePassword),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.wrongEmail,
                style: theme.textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: isLoading ? null : _backToEmailStep,
                child: Text(l10n.useDifferentEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
