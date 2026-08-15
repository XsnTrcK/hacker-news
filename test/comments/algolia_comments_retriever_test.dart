import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/comments/apis/algolia_comments_api.dart';
import 'package:hackernews/models/item.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import '../support/hive_test_support.dart';

final _storyNode = {
  "id": 100,
  "children": [
    {
      "id": 200,
      "created_at_i": 1000,
      "author": "bob",
      "text": "hello",
      "parent_id": 100,
      "children": [],
    },
    {
      "id": 201,
      "created_at_i": 1001,
      "author": "carol",
      "text": "world",
      "parent_id": 100,
      "children": [],
    },
  ],
};

StoryItem _story(int id) => StoryItem(
      id,
      0,
      'alice',
      ItemState(),
      'Story $id',
      10,
      const [],
      0,
      'https://example.com/$id',
    );

AlgoliaCommentsRetriever _retrieverWithClient() {
  final client = MockClient((request) async {
    return Response(jsonEncode(_storyNode), 200);
  });
  return AlgoliaCommentsRetriever(client);
}

void main() {
  late Directory hiveDir;

  setUp(() => hiveDir = setUpHive());
  tearDown(() => tearDownHive(hiveDir));

  test('comments never interacted with have no record', () async {
    final retriever = _retrieverWithClient();
    await retriever.init();
    await retriever.fetchComments(_story(100));

    final box = Hive.box<bool>('comments');
    expect(box.containsKey(200), isFalse);
    expect(box.containsKey(201), isFalse);
  });

  test('collapsing a comment writes a presence marker, not content',
      () async {
    final retriever = _retrieverWithClient();
    await retriever.init();
    await retriever.fetchComments(_story(100));

    retriever.collapseComment(200);

    final box = Hive.box<bool>('comments');
    expect(box.get(200), true);
  });

  test('re-expanding deletes the marker rather than overwriting it',
      () async {
    final retriever = _retrieverWithClient();
    await retriever.init();
    await retriever.fetchComments(_story(100));

    retriever.collapseComment(200);
    expect(Hive.box<bool>('comments').containsKey(200), isTrue);

    retriever.expandComment(200);
    expect(Hive.box<bool>('comments').containsKey(200), isFalse);
  });

  test('a comment collapsed in a prior session renders collapsed on revisit',
      () async {
    final first = _retrieverWithClient();
    await first.init();
    await first.fetchComments(_story(100));
    first.collapseComment(200);

    // Simulate reopening the thread: a fresh retriever, same on-disk box.
    final second = _retrieverWithClient();
    await second.init();
    await second.fetchComments(_story(100));

    expect(second.getComment(200).state.isExpanded, isFalse);
    expect(second.getComment(201).state.isExpanded, isTrue);
  });

  test('comment content is never persisted to the comments box', () async {
    final retriever = _retrieverWithClient();
    await retriever.init();
    await retriever.fetchComments(_story(100));
    retriever.collapseComment(200);

    // The box is typed Box<bool>, so it is structurally incapable of
    // holding comment text/kids/etc. — the strongest guarantee available.
    final box = Hive.box<bool>('comments');
    expect(box.values, everyElement(isA<bool>()));
  });
}
