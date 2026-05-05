import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/di/di.dart';
import 'package:new_project/core/navigation/main_shell_controller.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/people_discovery_row.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/domain/usecases/search_people_discovery_usecase.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/navigation/open_author_posts_screen.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';

/// Search players by name and send friend requests (or jump to Profile for incoming).
class ExplorePeopleScreen extends StatefulWidget {
  const ExplorePeopleScreen({super.key});

  @override
  State<ExplorePeopleScreen> createState() => _ExplorePeopleScreenState();
}

class _ExplorePeopleScreenState extends State<ExplorePeopleScreen> {
  final _search = TextEditingController();
  final _commentForAuthor = TextEditingController();
  Timer? _debounce;
  List<PeopleDiscoveryRow> _rows = const [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';
  String? _busyAddId;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _commentForAuthor.dispose();
    super.dispose();
  }

  Future<void> _fetch(String raw) async {
    final q = raw.trim();
    _lastQuery = q;
    if (q.length < 2) {
      setState(() {
        _rows = const [];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final r = await getIt<SearchPeopleDiscoveryUsecase>()(q);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
        _rows = const [];
      }),
      (list) => setState(() {
        _loading = false;
        _error = null;
        _rows = list;
      }),
    );
  }

  void _scheduleFetch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 360), () => _fetch(v));
  }

  void _openProfileTab() {
    getIt<MainShellController>().goToMainTab(4);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (p, c) =>
          (c.successMessage != null && c.successMessage != p.successMessage) ||
          (c.errorMessage != null && c.errorMessage != p.errorMessage),
      listener: (context, state) {
        if (_busyAddId != null) {
          setState(() => _busyAddId = null);
        }
        final msg = state.successMessage ?? '';
        if (msg.contains('Friend request') && _lastQuery.length >= 2) {
          _fetch(_lastQuery);
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('Explore people'),
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: scheme.surfaceTint,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _scheduleFetch,
                  onSubmitted: _fetch,
                  decoration: InputDecoration(
                    hintText: 'Search by username…',
                    prefixIcon: const Icon(Icons.person_search_rounded),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _search.clear();
                              _scheduleFetch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Type at least 2 characters. Find someone new or add them '
                  'as a friend.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_lastQuery.trim().length < 2)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_2_outlined,
                            size: 56,
                            color: scheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Jump in and meet players',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_rows.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No usernames match “${_lastQuery.trim()}”.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final row = _rows[i];
                      final u = row.user;
                      final name = u.username.trim().isEmpty
                          ? 'Player'
                          : u.username.trim();
                      final url = u.avatarUrl?.trim();
                      final link = row.link;
                      final bid = u.id.trim();
                      final busyAdd = _busyAddId == bid;

                      return Card(
                        elevation: 0,
                        color: scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _linkSubtitle(link),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _linkAction(
                                context: context,
                                link: link,
                                busyAdd: busyAdd,
                                onAdd: () {
                                  setState(() => _busyAddId = bid);
                                  context.read<HomeBloc>().add(
                                        HomeSendFriendRequest(userModel: u),
                                      );
                                },
                                onOpenPosts: () {
                                  openAuthorPostsScreen(
                                    context: context,
                                    authorId: u.id,
                                    authorName: u.username,
                                    commentController: _commentForAuthor,
                                  );
                                },
                                onOpenProfile: _openProfileTab,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _linkSubtitle(PeopleDiscoveryLink link) {
    switch (link) {
      case PeopleDiscoveryLink.friend:
        return 'Friends — open posts from the feed context';
      case PeopleDiscoveryLink.pendingOutgoing:
        return 'Request sent — waiting for them';
      case PeopleDiscoveryLink.pendingIncoming:
        return 'Wants to connect — accept on Profile';
      case PeopleDiscoveryLink.none:
        return 'Not connected yet';
    }
  }

  Widget _linkAction({
    required BuildContext context,
    required PeopleDiscoveryLink link,
    required bool busyAdd,
    required VoidCallback onAdd,
    required VoidCallback onOpenPosts,
    required VoidCallback onOpenProfile,
  }) {
    final scheme = Theme.of(context).colorScheme;
    switch (link) {
      case PeopleDiscoveryLink.friend:
        return TextButton(
          onPressed: onOpenPosts,
          child: const Text('Posts'),
        );
      case PeopleDiscoveryLink.pendingOutgoing:
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(Icons.schedule_rounded, color: scheme.outline, size: 22),
        );
      case PeopleDiscoveryLink.pendingIncoming:
        return FilledButton.tonal(
          onPressed: onOpenProfile,
          child: const Text('Profile'),
        );
      case PeopleDiscoveryLink.none:
        return FilledButton(
          onPressed: busyAdd ? null : onAdd,
          child: busyAdd
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : const Text('Add'),
        );
    }
  }
}
