import 'package:hackernews/comments/apis/algolia_comments_api.dart';
import 'package:hackernews/models/item.dart';
import 'package:http/http.dart';

AlgoliaCommentsRetriever? _commentsApi;

abstract class CommentsHandler {
  const CommentsHandler();

  Future init({bool deleteBox});
  Future<List<CommentItem>> fetchComments(ItemWithKids itemWithKids);
  CommentItem getComment(int commentId);
  void updateComment(CommentItem comment);
}

CommentsHandler getCommentsHandler({Client? client}) {
  if (_commentsApi == null) {
    _commentsApi = AlgoliaCommentsRetriever(client ?? Client());
    return _commentsApi!;
  }
  return _commentsApi!;
}
