import 'dart:convert';

import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/models/item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';

class AlgoliaCommentsRetriever implements CommentsHandler {
  static const _algoliaItemBase = 'https://hn.algolia.com/api/v1/items';

  final Client _httpClient;
  late Box<bool> _commentsBox;

  // Comment content is fetched from the network every time and never
  // persisted; this cache only lives for the current session so getComment
  // can look up a comment already fetched this run.
  final Map<int, CommentItem> _cache = {};

  AlgoliaCommentsRetriever(this._httpClient);

  @override
  Future init({bool deleteBox = false}) async {
    _commentsBox = await Hive.openBox<bool>("comments");
    if (deleteBox) {
      await _commentsBox.deleteFromDisk();
      _commentsBox = await Hive.openBox<bool>("comments");
    }
  }

  @override
  CommentItem getComment(int commentId) {
    final comment = _cache[commentId];
    if (comment == null) {
      throw Exception("Comment could not be found in the store");
    }
    return comment;
  }

  @override
  Future<List<CommentItem>> fetchComments(ItemWithKids itemWithKids) async {
    final response = await _httpClient
        .get(Uri.parse('$_algoliaItemBase/${itemWithKids.id}'));
    if (response.statusCode != 200) {
      throw Exception(
          'Algolia comments fetch failed for story ${itemWithKids.id}: HTTP ${response.statusCode}');
    }
    final Map<String, dynamic> storyNode = jsonDecode(response.body);
    final children = (storyNode['children'] as List?) ?? [];

    return children
        .map((child) => _flatten(child as Map<String, dynamic>))
        .toList();
  }

  CommentItem _flatten(Map<String, dynamic> node) {
    final children = (node['children'] as List?) ?? [];
    final id = node['id'] as int;
    final comment = CommentItem(
      id,
      node['created_at_i'] as int,
      (node['author'] as String?) ?? '',
      ItemState(isExpanded: !_commentsBox.containsKey(id)),
      (node['text'] as String?) ?? '',
      children.map((c) => (c as Map<String, dynamic>)['id'] as int).toList(),
      node['parent_id'] as int,
      false,
      false,
    );
    _cache[comment.id] = comment;

    for (final child in children) {
      _flatten(child as Map<String, dynamic>);
    }

    return comment;
  }

  @override
  void collapseComment(int commentId) => _commentsBox.put(commentId, true);

  @override
  void expandComment(int commentId) => _commentsBox.delete(commentId);
}
