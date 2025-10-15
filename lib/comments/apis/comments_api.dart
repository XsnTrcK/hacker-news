// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:convert';
import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:hackernews/services/config.dart' as config;

CommentsApiRetriever? _commentsApi;

abstract class CommentsHandler {
  const CommentsHandler();

  Future init({bool deleteBox});
  Future<List<CommentItem>> fetchComments(ItemWithKids itemWithKids);
  CommentItem getComment(int commentId);
  void updateComment(CommentItem comment);
}

class CommentsApiRetriever implements CommentsHandler {
  final Client _httpClient;
  late Box<String> _commentsBox;

  CommentsApiRetriever(this._httpClient);

  @override
  Future init({bool deleteBox = false}) async {
    _commentsBox = await Hive.openBox<String>("comments");
    if (deleteBox) {
      _commentsBox.deleteFromDisk();
    }
  }

  Future<CommentItem> _downloadComment(int commentId) async {
    String? commentString;
    if (!_commentsBox.containsKey(commentId)) {
      final response = await _httpClient.get(config.getItemUri(commentId));
      commentString = response.body;
      _commentsBox.put(commentId, commentString);
    } else {
      commentString = _commentsBox.get(commentId);
    }

    return Item.fromJson(commentString!) as CommentItem;
  }

  @override
  CommentItem getComment(int commentId) {
    if (!_commentsBox.containsKey(commentId)) {
      throw Exception("Comment could not be found in the store");
    } else {
      return Item.fromJson(_commentsBox.get(commentId)!) as CommentItem;
    }
  }

  @override
  Future<List<CommentItem>> fetchComments(ItemWithKids itemWithKids) async {
    if (itemWithKids.childrenIds.isEmpty) return [];
    var results = await Future.wait(
      itemWithKids.childrenIds.map((childId) => _downloadComment(childId)),
    );
    await Future.wait(
      results.map((childComment) => _fetchComments(childComment)),
    );

    return results;
  }

  Future _fetchComments(CommentItem commentItem) async {
    if (commentItem.childrenIds.isEmpty) return;
    var results = await Future.wait(
      commentItem.childrenIds.map((childId) => _downloadComment(childId)),
    );
    await Future.wait(
      results.map((childComment) => _fetchComments(childComment)),
    );
  }

  @override
  Future updateComment(CommentItem comment) async {
    _commentsBox.put(comment.id, jsonEncode(comment.toMap()));
  }
}

CommentsHandler getCommentsHandler({Client? client}) {
  if (_commentsApi == null) {
    _commentsApi = CommentsApiRetriever(client ?? Client());
    return _commentsApi!;
  }
  return _commentsApi!;
}
