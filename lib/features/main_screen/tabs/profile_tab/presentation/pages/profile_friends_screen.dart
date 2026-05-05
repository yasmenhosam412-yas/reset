import 'package:flutter/material.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/remove_home_friend_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/domain/usecases/get_online_friends_usecase.dart';

/// Full list of accepted friends (same source as the Online tab).
class ProfileFriendsScreen extends StatefulWidget {
  const ProfileFriendsScreen({super.key});

  @override
  State<ProfileFriendsScreen> createState() => _ProfileFriendsScreenState();
}

class _ProfileFriendsScreenState extends State<ProfileFriendsScreen> {
  List<UserModel> _friends = const [];
  bool _loading = true;
  String? _error;
  String? _unfriendingUserId;

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
    final result = await getIt<GetOnlineFriendsUsecase>()();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _friends = const [];
      }),
      (list) {
        final sorted = List<UserModel>.from(list)
          ..sort(
            (a, b) => a.username.toLowerCase().compareTo(
                  b.username.toLowerCase(),
                ),
          );
        setState(() {
          _loading = false;
          _friends = sorted;
        });
      },
    );
  }

  Future<void> _confirmUnfriend(UserModel friend) async {
    final name = friend.username.trim().isEmpty
        ? 'this player'
        : friend.username.trim();
    final fid = friend.id.trim();
    if (fid.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove friend?'),
          content: Text(
            '$name will be removed from your friends. You can send a new '
            'request later from Home.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _unfriendingUserId = fid);
    final result = await getIt<RemoveHomeFriendUsecase>()(friendUserId: fid);
    if (!mounted) return;
    setState(() => _unfriendingUserId = null);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from friends')),
        );
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Friends'),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
      ),
      body: SafeArea(
        child: RefreshIndicator(
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : _friends.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 48,
                              color: scheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No friends yet',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accept requests below or send one from someone’s '
                              'post on Home.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _friends.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = _friends[index];
                            final name = u.username.trim().isEmpty
                                ? 'Player'
                                : u.username.trim();
                            final url = u.avatarUrl?.trim();
                            final busy =
                                _unfriendingUserId == u.id.trim() && _unfriendingUserId != null;
                            return Card(
                              elevation: 0,
                              color: scheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: scheme.outline.withValues(alpha: 0.08),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: homeFeedAvatarColor(name),
                                  backgroundImage: url != null && url.isNotEmpty
                                      ? NetworkImage(url)
                                      : null,
                                  child: url == null || url.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove friend',
                                  onPressed: busy || u.id.trim().isEmpty
                                      ? null
                                      : () => _confirmUnfriend(u),
                                  icon: busy
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: scheme.primary,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_remove_outlined,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
