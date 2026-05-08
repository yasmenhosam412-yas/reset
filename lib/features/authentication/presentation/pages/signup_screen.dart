import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_event.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitSignup() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSignupEvent(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  String _friendlySignupError(String raw) {
    final l10n = context.l10n;
    final m = raw.trim().toLowerCase();
    final usernameTaken =
        (m.contains('username') &&
            (m.contains('duplicate') ||
                m.contains('unique') ||
                m.contains('already exists') ||
                m.contains('already taken') ||
                m.contains('23505'))) ||
        m.contains('username already taken');
    if (usernameTaken) {
      return l10n.signupFriendlyUsernameTaken;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.authState == AuthState.errorSignup && state.error != null) {
            final message = _friendlySignupError(state.error!);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
          if (state.authState == AuthState.loadedSignup) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.accountCreatedSuccessfully)),
            );
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
                                    Icons.person_add_alt_1_rounded,
                                    size: 28,
                                    color: colors.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.signupHeroTitle,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.signupHeroSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onPrimary.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.signUp,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: l10n.username,
                                      hintText: l10n.usernameHint,
                                      prefixIcon: const Icon(Icons.person_outline_rounded),
                                      filled: true,
                                      fillColor: colors.surfaceContainerHighest.withValues(
                                        alpha: 0.45,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      final username = value?.trim() ?? '';
                                      if (username.isEmpty) {
                                        return l10n.usernameRequired;
                                      }
                                      if (username.length < 3) {
                                        return l10n.usernameAtLeast3;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: l10n.emailAddress,
                                      hintText: l10n.emailHint,
                                      prefixIcon: const Icon(Icons.alternate_email),
                                      filled: true,
                                      fillColor: colors.surfaceContainerHighest.withValues(
                                        alpha: 0.45,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return l10n.emailRequired;
                                      }
                                      if (!email.contains('@')) {
                                        return l10n.validEmailRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!isLoading) _submitSignup();
                                    },
                                    decoration: InputDecoration(
                                      labelText: l10n.password,
                                      prefixIcon: const Icon(Icons.password_rounded),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: colors.surfaceContainerHighest.withValues(
                                        alpha: 0.45,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      final password = value ?? '';
                                      if (password.isEmpty) {
                                        return l10n.passwordRequired;
                                      }
                                      if (password.length < 6) {
                                        return l10n.passwordAtLeast6;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: isLoading ? null : _submitSignup,
                                      child: isLoading
                                          ? SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: colors.onPrimary,
                                              ),
                                            )
                                          : Text(l10n.createAccount),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.alreadyMember,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => context.go(AppRouter.loginPath),
                                        child: Text(l10n.login),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
}
