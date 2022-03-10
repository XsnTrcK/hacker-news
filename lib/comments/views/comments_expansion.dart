import 'package:hackernews/comments/apis/comments_api.dart';
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
  late CommentsHandler _commentsHandler;

  @override
  void initState() {
    super.initState();
    _commentsHandler = getCommentsHandler();
  }

  Widget itemBuilder(CommentItem comment) {
    _isExpanded = comment.state.isExpanded;
    return ExpansionTile(
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      maintainState: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 5),
      textColor: Colors.white, // TODO: Responsive to Brightness
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        _commentsHandler
            .updateComment(comment.copyWith(ItemState(isExpanded: expanded)));
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
    var comment = getCommentsHandler().getComment(widget.commentId);
    return comment.isDeleted ? const SizedBox.shrink() : itemBuilder(comment);
  }
}
