import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/comments/bloc/comments_bloc.dart';
import 'package:hackernews/comments/bloc/comments_events.dart';
import 'package:hackernews/comments/bloc/comments_state.dart';
import 'package:hackernews/comments/views/comments_expansion.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:hackernews/components/custom_text.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/services/link_handler.dart';

class CommentsSection extends StatelessWidget {
  final ItemWithKids itemWithKids;
  final Widget? startWidget;
  final int? childIdRoot;
  const CommentsSection(this.itemWithKids,
      {super.key, this.startWidget, this.childIdRoot});

  @override
  Widget build(BuildContext context) {
    final theme = fluent_ui.FluentTheme.of(context);
    return BlocProvider(
      create: (_) =>
          CommentsBloc(getCommentsHandler())..add(FetchComments(itemWithKids)),
      child: BlocBuilder<CommentsBloc, CommentsState>(
        builder: (context, state) {
          switch (state.status) {
            case CommentsStatus.success:
              final commentWidgets = state.comments!
                  .map((comment) =>
                      CommentsExpansion(comment.id, key: ValueKey(comment.id)))
                  .toList();
              if (childIdRoot != null) {
                final index = commentWidgets
                    .indexWhere((widget) => widget.commentId == childIdRoot);
                if (index != -1) {
                  commentWidgets.removeAt(index);
                }
                commentWidgets.insert(
                  0,
                  CommentsExpansion(
                    childIdRoot!,
                    key: ValueKey(childIdRoot),
                    highlighted: true,
                  ),
                );
              }
              return Material(
                color: theme.scaffoldBackgroundColor,
                child: Column(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: pendingCommentLinkChecks,
                      builder: (context, pendingCount, _) => pendingCount > 0
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CustomText(
                                    'Checking for HN discussion',
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 60,
                                    child: fluent_ui.ProgressBar(),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        children: startWidget == null
                            ? commentWidgets
                            : [startWidget!, ...commentWidgets],
                      ),
                    ),
                  ],
                ),
              );
            case CommentsStatus.failure:
              return const Center(child: Text('Failed to fetch posts'));
            case CommentsStatus.initial:
            default:
              return const Center(child: fluent_ui.ProgressBar());
          }
        },
      ),
    );
  }
}
