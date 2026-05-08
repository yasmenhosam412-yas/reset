import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_event.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';

class ProfileDeleteAccountButton extends StatelessWidget {
  const ProfileDeleteAccountButton({
    super.key,
    required this.scheme,
  });

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error.withValues(alpha: 0.55)),
      ),
      onPressed: () => _confirmAndDelete(context),
      icon: const Icon(Icons.delete_forever_rounded),
      label: Text(l10n.deleteAccount),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final l10n = context.l10n;
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountQuestion),
        content: Text(
          l10n.deleteAccountMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          BlocConsumer<AuthBloc, AuthBlocState>(
            listener: (context, state) {
              if (state.authState == AuthState.loadedOut) {
                context.go(AppRouter.loginPath);
                context.read<HomeBloc>().add(ResetHomeEvent());
                context.read<OnlineBloc>().add(ResetOnlineTab());
                _showSnack(context, l10n.accountDeleted);
              } else if (state.authState == AuthState.errorOut) {
                _showSnack(context, state.error ?? l10n.failedToDeleteAccount);
              }
            },
            builder: (context, state) {
              return (state.authState == AuthState.loading)
                  ? Center(
                      child: CircularProgressIndicator(
                        color: scheme.primary,
                      ),
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthDeleteAccountEvent());
                      },
                      child: Text(l10n.delete),
                    );
            },
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

