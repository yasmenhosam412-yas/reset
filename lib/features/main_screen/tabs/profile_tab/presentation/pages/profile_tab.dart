import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_project/core/di/di.dart';
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
import 'package:url_launcher/url_launcher.dart';

const _kAppVersion = '0.1.0';

const _kPlayStoreListing =
    'https://play.google.com/store/apps/details?id=com.example.new_project';
const _kAppStoreListing =
    'https://apps.apple.com/app/id0000000000';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final ProfileBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProfileBloc>()..add(ProfileLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _onRefresh(BuildContext context) async {
    _bloc.add(ProfileLoadRequested());
    await _bloc.stream.firstWhere((s) => s.status != ProfileStatus.loading);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    if (kIsWeb) {
      _showSnack(
        context,
        'Rate us from your phone’s app store once the app is published.',
      );
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
      _showSnack(context, 'Could not open the store link.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onAccountRowTap(BuildContext context, String title) {
    switch (title) {
      case 'Privacy & security':
        context.push(AppRouter.privacySecurityPath);
      case 'Rate the app':
        unawaited(_openStoreListing(context));
      case 'Help & support':
        context.push(AppRouter.helpSupportPath);
      default:
        _showSnack(context, 'Coming soon.');
    }
  }

  List<Widget> _buildSlivers({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
    required ProfileDashboardModel dashboard,
    required ProfileState state,
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
            editBusy: state.profileSaveBusy,
            onEditTap: () => unawaited(_onEditProfile(context, dashboard)),
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
      profileSectionTitleSliver(theme, 'Preferences', top: 26),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfilePreferencesCard(
            scheme: scheme,
            pushNotifications: dashboard.pushNotificationsEnabled,
            matchInvites: dashboard.acceptsMatchInvites,
            onPushChanged: (v) =>
                _bloc.add(ProfilePushNotificationsChanged(v)),
            onMatchInvitesChanged: (v) =>
                _bloc.add(ProfileMatchInvitesChanged(v)),
          ),
        ),
      ),
      profileSectionTitleSliver(theme, 'Account', top: 26),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: ProfileAccountSettingsCard(
            scheme: scheme,
            onItemTap: (title) => _onAccountRowTap(context, title),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
        sliver: SliverToBoxAdapter(
          child: Text(
            'v$_kAppVersion',
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

  @override
  Widget build(BuildContext context) {
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
              onRetry: () => _bloc.add(ProfileLoadRequested()),
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
                    state: state,
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
  String _pickedLabel = 'No new photo';

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
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                _pickedLabel,
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
                    _pickedLabel = 'New photo selected';
                  });
                },
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Choose profile photo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
