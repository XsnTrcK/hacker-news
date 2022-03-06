abstract class CommentEvent {
  const CommentEvent();
}

class FetchComment extends CommentEvent {
  final int commentId;
  const FetchComment(this.commentId);
}
