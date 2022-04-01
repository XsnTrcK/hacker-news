import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/comments/views/comment.dart';
import 'package:hackernews/models/item.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:hackernews/services/theme_extensions.dart';

class CommentsExpansion extends StatefulWidget {
  final int commentId;
  const CommentsExpansion(this.commentId, {Key? key}) : super(key: key);

  @override
  _CommentsExpansionState createState() => _CommentsExpansionState();
}

class _CommentsExpansionState extends State<CommentsExpansion> {
  bool _isExpanded = true;
  late CommentsHandler _commentsHandler;

  @override
  void initState() {
    super.initState();
    _commentsHandler = getCommentsHandler();
  }

  Widget itemBuilder(CommentItem comment, fluent_ui.ThemeData theme) {
    _isExpanded = comment.state.isExpanded;
    return ExpansionTile(
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      maintainState: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 5),
      textColor: theme.textColor,
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        comment.state.isExpanded = expanded;
        _commentsHandler.updateComment(comment);
        setState(() => _isExpanded = expanded);
      },
      title: Comment(
        comment,
        isExpanded: _isExpanded,
      ),
      children: comment.childrenIds
          .map(
            (id) => Container(
              child: CommentsExpansion(id),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.textColor, width: 1),
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
    final theme = fluent_ui.FluentTheme.of(context);
    var comment = getCommentsHandler().getComment(widget.commentId);
    return comment.isDeleted
        ? const SizedBox.shrink()
        : itemBuilder(comment, theme);
  }
}
