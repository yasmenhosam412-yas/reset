import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_event.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_state.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state.authState == AuthState.errorLogin && state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.authState == AuthState.loadedLogin) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.loggedInSuccessfully)),
            );
            context.go(AppRouter.mainScreenPath);
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
                  colors.tertiaryContainer.withValues(alpha: 0.92),
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
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 28,
                                    color: colors.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.loginHeroTitle,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.loginHeroSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.9,
                                    ),
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
                                    l10n.signIn,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: l10n.emailHint,
                                      labelText: l10n.emailAddress,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email,
                                      ),
                                      filled: true,
                                      fillColor: colors.surfaceContainerHighest
                                          .withValues(alpha: 0.45),
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
                                      if (!isLoading) _submitLogin();
                                    },
                                    decoration: InputDecoration(
                                      labelText: l10n.password,
                                      prefixIcon: const Icon(
                                        Icons.password_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: colors.surfaceContainerHighest
                                          .withValues(alpha: 0.45),
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
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => context.push(
                                              AppRouter.forgotPasswordPath,
                                            ),
                                      child: Text(l10n.forgotPassword),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: isLoading
                                          ? null
                                          : _submitLogin,
                                      child: isLoading
                                          ? SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: colors.onPrimary,
                                              ),
                                            )
                                          : Text(l10n.continueText),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.newHere,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => context.push(
                                                AppRouter.signupPath,
                                              ),
                                        child: Text(l10n.createAccount),
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
