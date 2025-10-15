import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/comments/bloc/comments_bloc.dart';
import 'package:hackernews/comments/bloc/comments_events.dart';
import 'package:hackernews/comments/bloc/comments_state.dart';
import 'package:hackernews/comments/views/comments_expansion.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:hackernews/models/item.dart';

class CommentsSection extends StatelessWidget {
  final ItemWithKids itemWithKids;
  final Widget? startWidget;
  const CommentsSection(this.itemWithKids, {super.key, this.startWidget});

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
              return Material(
                color: theme.scaffoldBackgroundColor,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  children: startWidget == null
                      ? commentWidgets
                      : [startWidget!, ...commentWidgets],
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
