import 'dart:convert';

import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';

class AlgoliaCommentsRetriever implements CommentsHandler {
  static const _algoliaItemBase = 'https://hn.algolia.com/api/v1/items';

  final Client _httpClient;
  late Box<String> _commentsBox;

  AlgoliaCommentsRetriever(this._httpClient);

  @override
  Future init({bool deleteBox = false}) async {
    _commentsBox = await Hive.openBox<String>("comments");
    if (deleteBox) {
      _commentsBox.deleteFromDisk();
    }
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
    final response = await _httpClient
        .get(Uri.parse('$_algoliaItemBase/${itemWithKids.id}'));
    final Map<String, dynamic> storyNode = jsonDecode(response.body);
    final children = (storyNode['children'] as List?) ?? [];

    return children
        .map((child) => _flatten(child as Map<String, dynamic>))
        .toList();
  }

  CommentItem _flatten(Map<String, dynamic> node) {
    final children = (node['children'] as List?) ?? [];
    final comment = CommentItem(
      node['id'] as int,
      node['created_at_i'] as int,
      (node['author'] as String?) ?? '',
      ItemState(),
      (node['text'] as String?) ?? '',
      children.map((c) => (c as Map<String, dynamic>)['id'] as int).toList(),
      node['parent_id'] as int,
      false,
      false,
    );
    _commentsBox.put(comment.id, jsonEncode(comment.toMap()));

    for (final child in children) {
      _flatten(child as Map<String, dynamic>);
    }

    return comment;
  }

  @override
  Future updateComment(CommentItem comment) async {
    _commentsBox.put(comment.id, jsonEncode(comment.toMap()));
  }
}
