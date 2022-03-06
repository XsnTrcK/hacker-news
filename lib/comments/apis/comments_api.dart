// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:hackernews/services/config.dart' as config;

abstract class CommentsFetcher {
  const CommentsFetcher();

  Future fetchComments(ItemWithKids itemWithKids);
}

abstract class CommentsApi {
  const CommentsApi();

  Future<CommentItem> getComment(int commentId);
}

class CommentsApiRetriever implements CommentsApi, CommentsFetcher {
  final Client _httpClient;
  Box<String>? _commentsBox;

  CommentsApiRetriever(this._httpClient);

  @override
  Future<CommentItem> getComment(int commentId) async {
    _commentsBox ??= await Hive.openBox<String>("comments");
    String? commentString;
    if (_commentsBox!.containsKey(commentId)) {
      commentString = _commentsBox!.get(commentId);
    } else {
      final response = await _httpClient.get(config.getItemUri(commentId));
      commentString = response.body;
    }
    if (commentString == null) {
      throw Exception("Unable to successfully retrieve comment");
    }
    return Item.fromJson(commentString) as CommentItem;
  }

  @override
  Future fetchComments(ItemWithKids itemWithKids) async {
    _commentsBox ??= await Hive.openBox<String>("comments");
    await Future.wait(
        itemWithKids.childrenIds.map((childId) => getComment(childId)));
  }
}
