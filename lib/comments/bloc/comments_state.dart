import 'package:hackernews/models/item.dart';

enum CommentsStatus { initial, success, failure }

class CommentsState {
  final List<CommentItem>? comments;
  final CommentsStatus status;

  const CommentsState({
    this.status = CommentsStatus.initial,
    this.comments,
  });
}
