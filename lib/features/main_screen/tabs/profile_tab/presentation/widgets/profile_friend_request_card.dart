import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/profile_dashboard_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/utils/home_feed_ui.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_bloc.dart';
import 'package:new_project/features/main_screen/tabs/profile_tab/presentation/bloc/profile_event.dart';

Color profileAvatarColorForName(String name) {
  final i = name.hashCode.abs() % Colors.primaries.length;
  return Colors.primaries[i];
}

class ProfileFriendRequestCard extends StatelessWidget {
  const ProfileFriendRequestCard({
    super.key,
    required this.request,
    required this.theme,
    required this.scheme,
    this.requestBusy = false,
  });

  final IncomingFriendRequestModel request;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool requestBusy;

  @override
  Widget build(BuildContext context) {
    final from = request.fromUser;
    final name =
        from.username.trim().isEmpty ? 'Someone' : from.username;
    final time = homeFeedTimeAgo(request.createdAt);
    final url = from.avatarUrl?.trim();
    final hasAvatar = url != null && url.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: profileAvatarColorForName(name),
                  foregroundColor: Colors.white,
                  backgroundImage: hasAvatar ? NetworkImage(url) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Wants to be friends',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: requestBusy
                        ? null
                        : () => context.read<ProfileBloc>().add(
                              ProfileFriendRequestResponded(
                                requestId: request.requestId,
                                accept: false,
                              ),
                            ),
                    child: requestBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: requestBusy
                        ? null
                        : () => context.read<ProfileBloc>().add(
                              ProfileFriendRequestResponded(
                                requestId: request.requestId,
                                accept: true,
                              ),
                            ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
