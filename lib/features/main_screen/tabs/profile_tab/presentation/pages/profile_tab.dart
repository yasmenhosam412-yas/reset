import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/app_locale_controller.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/widgets/tab_loading_skeletons.dart';
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
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_sign_out_button.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_delete_account_button.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/navigation/open_author_posts_screen.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/pages/saved_posts_screen.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/profile_blocked_users_screen.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/profile_friends_screen.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/pages/profile_online_challenges_screen.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/widgets/profile_stats_row.dart';
import 'package:url_launcher/url_launcher.dart';

const _kAppVersion = '0.1.0';

const _kPlayStoreListing =
    'https://play.google.com/store/apps/details?id=com.example.new_project';
const _kAppStoreListing = 'https://apps.apple.com/app/id0000000000';

Widget _profileSectionTitleSliver(
  ThemeData theme,
  ColorScheme scheme,
  String title, {
  double top = 22,
}) {
  return SliverPadding(
    padding: EdgeInsets.fromLTRB(20, top, 20, 10),
    sliver: SliverToBoxAdapter(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileQuickActionCard extends StatelessWidget {
  const _ProfileQuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = iconColor ?? scheme.primary;
    return Material(
      color: scheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final ProfileBloc _bloc;
  final _authorPostsCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProfileBloc>()..add(ProfileLoadRequested());
  }

  @override
  void dispose() {
    _authorPostsCommentController.dispose();
    _bloc.close();
    super.dispose();
  }

  Future<void> _onRefresh(BuildContext context) async {
    _bloc.add(ProfileLoadRequested());
    await _bloc.stream.firstWhere((s) => s.status != ProfileStatus.loading);
  }

  void _openSavedPosts(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SavedPostsScreen(
          commentController: _authorPostsCommentController,
        ),
      ),
    );
  }

  void _openBlockedUsers(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileBlockedUsersScreen(),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onEditProfile(
    BuildContext context,
    ProfileDashboardModel dashboard,
  ) async {
    if (!context.mounted) return;
    final initial = dashboard.user.username.trim();
    final result = await showDialog<_EditProfileDialogResult>(
      context: context,
      builder: (ctx) => _EditProfileDialog(initialName: initial),
    );

    if (result != null && context.mounted) {
      _bloc.add(
        ProfileEdited(
          username: result.username,
          avatarBytes: result.avatarBytes,
          avatarContentType: result.avatarContentType,
        ),
      );
    }
  }

  Future<void> _openStoreListing(BuildContext context) async {
    final l10n = context.l10n;
    if (kIsWeb) {
      _showSnack(context, l10n.rateAppFromPhoneHint);
      return;
    }
    final uri = Uri.parse(
      defaultTargetPlatform == TargetPlatform.iOS
          ? _kAppStoreListing
          : _kPlayStoreListing,
    );
    final ok = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (!ok) {
      _showSnack(context, l10n.couldNotOpenStoreLink);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onAccountRowTap(BuildContext context, int index) {
    final l10n = context.l10n;
    switch (index) {
      case 0:
        context.push(AppRouter.privacySecurityPath);
      case 1:
        unawaited(_openStoreListing(context));
      case 2:
        context.push(AppRouter.helpSupportPath);
      default:
        _showSnack(context, l10n.comingSoon);
    }
  }

  List<Widget> _buildSlivers({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
    required ProfileDashboardModel dashboard,
    required ProfileState state,
  }) {
    final l10n = context.l10n;
    final currentCode =
        AppLocaleController.instance.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final requests = dashboard.incomingFriendRequests;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        sliver: SliverToBoxAdapter(
          child: Text(
            l10n.profile,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
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
            editBusy: state.profileSaveBusy,
            onEditTap: () => unawaited(_onEditProfile(context, dashboard)),
          ),
        ),
      ),
      _profileSectionTitleSliver(theme, scheme, l10n.overview, top: 22),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfileStatsOverviewRow(
            theme: theme,
            scheme: scheme,
            stats: dashboard.stats,
            onPostsTap: () => openAuthorPostsScreen(
              context: context,
              authorId: dashboard.user.id,
              authorName: dashboard.user.username,
              commentController: _authorPostsCommentController,
            ),
            onFriendsTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileFriendsScreen(),
                ),
              );
            },
            onChallengesTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileOnlineChallengesScreen(),
                ),
              );
            },
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${l10n.saves}. ${l10n.openSavedPosts}',
                  child: _ProfileQuickActionCard(
                    icon: Icons.bookmarks_outlined,
                    title: l10n.saves,
                    subtitle: l10n.openSavedPosts,
                    onTap: () => _openSavedPosts(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      '${l10n.blockedUsersTitle}. ${l10n.openBlockedUsersSubtitle}',
                  child: _ProfileQuickActionCard(
                    icon: Icons.block_rounded,
                    iconColor: scheme.error,
                    title: l10n.blockedUsersTitle,
                    subtitle: l10n.openBlockedUsersSubtitle,
                    onTap: () => _openBlockedUsers(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      _profileSectionTitleSliver(theme, scheme, l10n.friendRequests, top: 26),
      if (requests.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 28,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.noPendingFriendRequests,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
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
              final r = requests[index];
              final busy = state.busyFriendRequestId == r.requestId;
              return ProfileFriendRequestCard(
                request: r,
                theme: theme,
                scheme: scheme,
                requestBusy: busy,
              );
            },
          ),
        ),
      _profileSectionTitleSliver(theme, scheme, l10n.preferences, top: 26),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          // Push off → clears FCM token + deletes device token (PushBootstrap).
          child: ProfilePreferencesCard(
            scheme: scheme,
            pushNotifications: dashboard.pushNotificationsEnabled,
            matchInvites: dashboard.acceptsMatchInvites,
            onPushChanged: (v) => _bloc.add(ProfilePushNotificationsChanged(v)),
            onMatchInvitesChanged: (v) =>
                _bloc.add(ProfileMatchInvitesChanged(v)),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Material(
            color: scheme.surface,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.language,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'en',
                          label: Text(l10n.english),
                        ),
                        ButtonSegment<String>(
                          value: 'ar',
                          label: Text(l10n.arabic),
                        ),
                      ],
                      selected: {currentCode == 'ar' ? 'ar' : 'en'},
                      onSelectionChanged: (values) {
                        if (values.isEmpty) return;
                        unawaited(
                          AppLocaleController.instance.setLocaleCode(
                            values.first,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      _profileSectionTitleSliver(theme, scheme, l10n.account, top: 26),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfileAccountSettingsCard(
            scheme: scheme,
            onItemTap: (index) => _onAccountRowTap(context, index),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                'v$_kAppVersion',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              ProfileSignOutButton(
                scheme: scheme,
                onConfirmed: () async {
                  context.read<AuthBloc>().add(AuthLogoutEvent());
                },
              ),
              const SizedBox(height: 12),
              ProfileDeleteAccountButton(scheme: scheme),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (prev, curr) =>
            (curr.errorMessage != null &&
                curr.errorMessage != prev.errorMessage) ||
            (curr.successMessage != null &&
                curr.successMessage != prev.successMessage),
        listener: (context, state) {
          final err = state.errorMessage;
          if (err != null) _showSnack(context, err);
          final ok = switch (state.successType) {
            ProfileSuccessType.friendRequestAccepted =>
              l10n.friendRequestAccepted,
            ProfileSuccessType.friendRequestDeclined =>
              l10n.friendRequestDeclined,
            ProfileSuccessType.profileUpdated => l10n.profileUpdated,
            null => state.successMessage,
          };
          if (ok != null) _showSnack(context, ok);
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading &&
              state.dashboard == null) {
            return Scaffold(
              body: SafeArea(child: TabLoadingSkeletons.profileTab(context)),
            );
          }

          if (state.status == ProfileStatus.failure &&
              state.dashboard == null) {
            return ProfileErrorView(
              message: state.errorMessage ?? l10n.couldNotLoadProfile,
              onRetry: () => _bloc.add(ProfileLoadRequested()),
            );
          }

          final dashboard = state.dashboard;
          if (dashboard == null) {
            return const SizedBox.shrink();
          }

          return Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.28, 1],
                  colors: [
                    Color.lerp(
                          scheme.primaryContainer,
                          scheme.surface,
                          0.35,
                        ) ??
                        scheme.surface,
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => _onRefresh(context),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: _buildSlivers(
                      context: context,
                      theme: theme,
                      scheme: scheme,
                      dashboard: dashboard,
                      state: state,
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

class _EditProfileDialogResult {
  const _EditProfileDialogResult({
    required this.username,
    this.avatarBytes,
    this.avatarContentType,
  });

  final String username;
  final Uint8List? avatarBytes;
  final String? avatarContentType;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameCtrl;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List? _pickedBytes;
  String? _pickedContentType;
  String _pickedLabel = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.editProfile),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '', hintText: '')
                    .copyWith(
                      labelText: l10n.username,
                      hintText: l10n.usernameAllowedHint,
                    ),
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                validator: (v) {
                  final name = (v ?? '').trim();
                  if (name.isEmpty) {
                    return l10n.enterUsername;
                  }
                  if (name.length < 3) {
                    return l10n.usernameAtLeast3;
                  }
                  // if (!_usernamePattern.hasMatch(name)) {
                  //   return l10n.usernameAllowedChars;
                  // }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                _pickedLabel.isEmpty ? l10n.noNewPhoto : _pickedLabel,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final x = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    imageQuality: 85,
                  );
                  if (x == null) return;
                  final bytes = await x.readAsBytes();
                  final ct = x.mimeType ?? 'image/jpeg';
                  if (!mounted) return;
                  setState(() {
                    _pickedBytes = bytes;
                    _pickedContentType = ct;
                    _pickedLabel = l10n.newPhotoSelected;
                  });
                },
                icon: const Icon(Icons.photo_outlined),
                label: Text(l10n.chooseProfilePhoto),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _EditProfileDialogResult(
                username: _nameCtrl.text.trim(),
                avatarBytes: _pickedBytes,
                avatarContentType: _pickedContentType,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
