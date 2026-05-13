import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/core/utils/pagination_consts.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/get_home_blocked_users_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/unblock_home_user_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';

/// Users blocked by the signed-in account; unblock removes the [user_blocks] row.
class ProfileBlockedUsersScreen extends StatefulWidget {
  const ProfileBlockedUsersScreen({super.key});

  @override
  State<ProfileBlockedUsersScreen> createState() =>
      _ProfileBlockedUsersScreenState();
}

class _ProfileBlockedUsersScreenState extends State<ProfileBlockedUsersScreen> {
  List<UserModel> _blocked = const [];
  bool _loading = true;
  String? _error;
  String? _busyUnblockId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<GetHomeBlockedUsersUsecase>()();
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _blocked = const [];
      }),
      (list) {
        setState(() {
          _loading = false;
          _blocked = List<UserModel>.from(list, growable: false);
        });
      },
    );
  }

  void _refreshHomeAndOnline(BuildContext context) {
    context.read<HomeBloc>().add(
          HomePostsRequested(
            limit: PaginationConsts.limitPosts,
            offset: PaginationConsts.offsetPosts,
          ),
        );
    context.read<OnlineBloc>().add(OnlineLoadRequested());
  }

  Future<void> _confirmUnblock(UserModel user) async {
    final l10n = context.l10n;
    final name = user.username.trim().isEmpty ? l10n.player : user.username.trim();
    final uid = user.id.trim();
    if (uid.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.unblockUserTitle(name)),
          content: Text(l10n.unblockUserMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.unblockUser),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _busyUnblockId = uid);
    final result = await getIt<UnblockHomeUserUsecase>()(blockedUserId: uid);
    if (!mounted) return;
    setState(() => _busyUnblockId = null);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userUnblockedSnackbar(name))),
        );
        _refreshHomeAndOnline(context);
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.blockedUsersTitle),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.tonal(
                      onPressed: _load,
                      child: Text(l10n.retry),
                    ),
                  ),
                ],
              )
            : _blocked.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: [
                  Icon(Icons.block_rounded, size: 48, color: scheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noBlockedUsers,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: _blocked.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final u = _blocked[i];
                  final name = u.username.trim().isEmpty
                      ? l10n.player
                      : u.username.trim();
                  final url = u.avatarUrl?.trim();
                  final bid = u.id.trim();
                  final busy = _busyUnblockId == bid;
                  return Card(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: homeFeedAvatarColor(name),
                        backgroundImage: url != null && url.isNotEmpty
                            ? NetworkImage(url)
                            : null,
                        child: url == null || url.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: busy
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => _confirmUnblock(u),
                              child: Text(l10n.unblockUser),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
