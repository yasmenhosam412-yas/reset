import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/data/models/post_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_state.dart';

Future<void> showHomeCommentsSheet(
  BuildContext context, {
  required PostModel post,
  required TextEditingController commentController,
}) {
  if (post.id.isEmpty) return Future.value();

  commentController.clear();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      final sheetHeight = MediaQuery.sizeOf(ctx).height * 0.52;
      final scheme = Theme.of(ctx).colorScheme;
      final l10n = ctx.l10n;

      return BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: sheetHeight,
            child: BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (prev, curr) => prev.posts != curr.posts,
              builder: (context, state) {
                var live = post;
                for (final p in state.posts) {
                  if (p.id == post.id) {
                    live = p;
                    break;
                  }
                }

                void addComment() {
                  final t = commentController.text.trim();
                  if (t.isEmpty) return;
                  context.read<HomeBloc>().add(
                        HomeCommentCreateRequested(
                          postId: live.id,
                          comment: t,
                        ),
                      );
                  commentController.clear();
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            l10n.comments,
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '${live.comments.length}',
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: live.comments.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  l10n.noCommentsYetBeFirst,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: live.comments.length,
                              separatorBuilder: (context, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final c = live.comments[i];
                                final name = c.userModel.username;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(c.comment),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: l10n.writeAComment,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: addComment,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
