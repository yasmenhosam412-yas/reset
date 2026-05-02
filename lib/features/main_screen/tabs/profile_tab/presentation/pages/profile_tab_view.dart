import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_project/core/routing/app_router.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc.dart';
import 'package:new_project/features/authentication/presentation/controller/auth_bloc_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_bloc.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_event.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_state.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_account_settings_card.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_error_view.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_friend_request_card.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_hero_card.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_preferences_card.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_section_sliver.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_sign_out_button.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_stats_row.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  bool _pushNotifications = true;
  bool _matchInvites = true;

  Future<void> _onRefresh(BuildContext context) async {
    context.read<ProfileBloc>().add(ProfileLoadRequested());
    await context.read<ProfileBloc>().stream.firstWhere(
          (s) => s.status != ProfileStatus.loading,
        );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          (curr.errorMessage != null &&
              curr.errorMessage != prev.errorMessage) ||
          (curr.successMessage != null &&
              curr.successMessage != prev.successMessage),
      listener: (context, state) {
        final err = state.errorMessage;
        if (err != null) _showSnack(context, err);
        final ok = state.successMessage;
        if (ok != null) _showSnack(context, ok);
      },
      builder: (context, state) {
        if (state.status == ProfileStatus.loading && state.dashboard == null) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        if (state.status == ProfileStatus.failure && state.dashboard == null) {
          return ProfileErrorView(
            message: state.errorMessage ?? 'Could not load profile',
            onRetry: () =>
                context.read<ProfileBloc>().add(ProfileLoadRequested()),
          );
        }

        final dashboard = state.dashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _buildSlivers(
                  context: context,
                  theme: theme,
                  scheme: scheme,
                  dashboard: dashboard,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSlivers({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
    required ProfileDashboardModel dashboard,
  }) {
    final requests = dashboard.incomingFriendRequests;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfileHeroCard(
            theme: theme,
            scheme: scheme,
            dashboard: dashboard,
            onEditTap: () => _showSnack(context, 'Edit profile coming soon'),
          ),
        ),
      ),
      profileSectionTitleSliver(theme, 'Overview', top: 22),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfileStatsOverviewRow(
            theme: theme,
            scheme: scheme,
            stats: dashboard.stats,
          ),
        ),
      ),
      profileSectionTitleSliver(theme, 'Friend requests', top: 26),
      if (requests.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Text(
              'No pending friend requests.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return ProfileFriendRequestCard(
                request: requests[index],
                theme: theme,
                scheme: scheme,
              );
            },
          ),
        ),
      profileSectionTitleSliver(theme, 'Preferences', top: 26),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfilePreferencesCard(
            scheme: scheme,
            pushNotifications: _pushNotifications,
            matchInvites: _matchInvites,
            onPushChanged: (v) => setState(() => _pushNotifications = v),
            onMatchInvitesChanged: (v) => setState(() => _matchInvites = v),
          ),
        ),
      ),
      profileSectionTitleSliver(theme, 'Account', top: 26),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfileAccountSettingsCard(scheme: scheme),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
        sliver: SliverToBoxAdapter(
          child: Text(
            'v1.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverToBoxAdapter(
          child: ProfileSignOutButton(
            scheme: scheme,
            onConfirmed: () async {
              _showSnack(context, 'Signed out');
              context.read<AuthBloc>().add(AuthLogoutEvent());
              context.go(AppRouter.loginPath);
            },
          ),
        ),
      ),
    ];
  }
}
