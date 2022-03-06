import 'package:fluent_ui/fluent_ui.dart' as fluentUi;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/comments/bloc/comment_bloc.dart';
import 'package:hackernews/comments/bloc/comment_events.dart';
import 'package:hackernews/comments/bloc/comment_state.dart';
import 'package:hackernews/comments/views/comment.dart';
import 'package:hackernews/models/item.dart';
import 'package:flutter/material.dart';

class CommentsExpansion extends StatefulWidget {
  final int commentId;
  const CommentsExpansion(this.commentId, {Key? key}) : super(key: key);

  @override
  _CommentsExpansionState createState() => _CommentsExpansionState();
}

class _CommentsExpansionState extends State<CommentsExpansion> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    context.read<CommentBloc>().add(FetchComment(widget.commentId));
  }

  Widget itemBuilder(CommentItem comment) {
    if (comment.childrenIds.isEmpty) {
      return ListTile(
        title: Comment(comment),
        contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      );
    }
    return ExpansionTile(
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      maintainState: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 5),
      textColor: Colors.white, // TODO: Responsive to Brightness
      initiallyExpanded: true,
      onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
      title: Comment(
        comment,
        isExpanded: _isExpanded,
      ),
      children: comment.childrenIds
          .map(
            (id) => Container(
              child: CommentsExpansion(id),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white, width: 3),
                ),
              ),
              margin: const EdgeInsets.only(left: 20),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentBloc, CommentState>(
      builder: (context, state) {
        switch (state.status) {
          case CommentStatus.success:
            return state.comment?.isDeleted ?? true
                ? const SizedBox.shrink()
                : itemBuilder(state.comment!);
          case CommentStatus.failure:
            return const Center(child: Text('Failed to retrieve comment'));
          case CommentStatus.initial:
          default:
            return const Center(child: fluentUi.ProgressBar());
        }
      },
    );
  }
}
