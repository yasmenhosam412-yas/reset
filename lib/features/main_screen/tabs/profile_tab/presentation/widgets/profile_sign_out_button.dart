import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/core/utils/app_colors.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({
    super.key,
    required this.scheme,
    required this.onConfirmed,
  });

  final ColorScheme scheme;
  final Future<void> Function() onConfirmed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error.withValues(alpha: 0.55)),
      ),
      onPressed: () => _confirmAndSignOut(context),
      icon: const Icon(Icons.logout_rounded),
      label: Text(l10n.signOut),
    );
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final l10n = context.l10n;
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutQuestion),
        content: Text(
          l10n.signOutMessage,
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
                _showSnack(context, l10n.signedOut);
              } else if (state.authState == AuthState.errorOut) {
                _showSnack(context, state.error!);
              }
            },
            builder: (context, state) {
              return (state.authState == AuthState.loading)
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      onPressed: () {
                        onConfirmed();
                      },
                      child: Text(l10n.signOut),
                    );
            },
          ),
        ],
      ),
    );
    // if (!context.mounted || ok != true) return;
    // await onConfirmed();
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
