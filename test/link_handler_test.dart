import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/services/link_handler.dart';

class UrlOpenerSpy {
  final List<Uri> opened = [];

  Future<void> call(Uri uri) async {
    opened.add(uri);
  }
}

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

StoryItem _storyItem(int id) {
  return StoryItem(
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
}

CommentItem _commentItem(int id, int parentId) {
  return CommentItem(
    id,
    0,
    'bob',
    ItemState(),
    'Comment $id',
    const [],
    parentId,
    false,
    false,
  );
}

void main() {
  test('getItemOrOpenUrl returns titled item for story links', () async {
    final openSpy = UrlOpenerSpy();
    final story = _storyItem(1);
    final handler = LinkHandler(
      fetchItem: (id) async => id == 1 ? story : null,
      openUrl: openSpy.call,
    );

    final result = await handler
        .getItemOrOpenUrl('https://news.ycombinator.com/item?id=1');

    final (titledItem, item) = result;
    expect(titledItem, same(story));
    expect(item, isNull);
    expect(openSpy.opened, isEmpty);
  });

  test('getItemOrOpenUrl resolves comment links', () async {
    final openSpy = UrlOpenerSpy();
    final story = _storyItem(100);
    final comment = _commentItem(200, 100);
    final handler = LinkHandler(
      fetchItem: (id) async {
        if (id == 200) return comment;
        if (id == 100) return story;
        return null;
      },
      openUrl: openSpy.call,
    );

    final (titledItem, item) = await handler
        .getItemOrOpenUrl('https://news.ycombinator.com/item?id=200');

    expect(titledItem, same(story));
    expect(item, same(comment));
    expect(openSpy.opened, isEmpty);
  });

  test('getItemOrOpenUrl opens URL when no titled parent found', () async {
    final openSpy = UrlOpenerSpy();
    final comment = _commentItem(200, 300);
    final handler = LinkHandler(
      fetchItem: (id) async => id == 200 ? comment : null,
      openUrl: openSpy.call,
    );

    final (titledItem, item) = await handler
        .getItemOrOpenUrl('https://news.ycombinator.com/item?id=200');

    expect(titledItem, isNull);
    expect(item, isNull);
    expect(openSpy.opened.length, 1);
  });

  test('getItemOrOpenUrl opens non-HN URLs', () async {
    final openSpy = UrlOpenerSpy();
    final handler = LinkHandler(
      fetchItem: (id) async => null,
      openUrl: openSpy.call,
    );

    final (titledItem, item) =
        await handler.getItemOrOpenUrl('https://example.com');

    expect(titledItem, isNull);
    expect(item, isNull);
    expect(openSpy.opened.single.toString(), 'https://example.com');
  });

  testWidgets('handleLinkTap pushes a route for titled items',
      (WidgetTester tester) async {
    final observer = TestNavigatorObserver();
    final story = _storyItem(1);
    final handler = LinkHandler(
      fetchItem: (id) async => story,
      openUrl: (uri) async {},
      buildArticle: (titledItem, _) => Text('article:${titledItem.id}'),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => handler.handleLinkTap(
                context,
                'https://news.ycombinator.com/item?id=1',
              ),
              child: const Text('tap'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pumpAndSettle();

    // Should have initial material page route + article route
    expect(observer.pushedRoutes.length, 2);
    expect(find.text('article:1'), findsOneWidget);
  });

  group('normalizeUrlForComparison', () {
    test('lowercases host and strips a trailing slash', () {
      expect(
        normalizeUrlForComparison('https://Example.com/Foo/'),
        normalizeUrlForComparison('https://example.com/Foo'),
      );
    });

    test('ignores query string and fragment', () {
      expect(
        normalizeUrlForComparison('https://example.com/foo?a=1#frag'),
        normalizeUrlForComparison('https://example.com/foo'),
      );
    });

    test('differs when the path differs', () {
      expect(
        normalizeUrlForComparison('https://example.com/foo'),
        isNot(normalizeUrlForComparison('https://example.com/bar')),
      );
    });
  });

  group('isVerifiedMatch', () {
    test('accepts a story URL matching after normalization', () {
      final story = StoryItem(1, 0, 'alice', ItemState(), 'Story', 10,
          const [], 0, 'https://example.com/foo/');

      expect(isVerifiedMatch('https://Example.com/foo?ref=hn', story), isTrue);
    });

    test('rejects a story with a different hostname', () {
      final story = _storyItem(1); // https://example.com/1
      expect(isVerifiedMatch('https://other.com/1', story), isFalse);
    });

    test('rejects a story with a different path', () {
      final story = _storyItem(1); // https://example.com/1
      expect(isVerifiedMatch('https://example.com/2', story), isFalse);
    });

    test('rejects a candidate with no URL (e.g. an Ask item)', () {
      final ask =
          AskItem(1, 0, 'alice', ItemState(), 'text', 'Ask HN', 10, const [], 0);
      expect(isVerifiedMatch('https://example.com/1', ask), isFalse);
    });

    test('rejects a null candidate', () {
      expect(isVerifiedMatch('https://example.com/1', null), isFalse);
    });
  });

  group('handleCommentLinkTap', () {
    testWidgets('delegates HN item links to the existing passthrough',
        (WidgetTester tester) async {
      final observer = TestNavigatorObserver();
      final story = _storyItem(1);
      var hnMatchCalls = 0;
      final handler = LinkHandler(
        fetchItem: (id) async => story,
        openUrl: (uri) async {},
        buildArticle: (titledItem, _) => Text('article:${titledItem.id}'),
        findHnMatch: (url) async {
          hnMatchCalls++;
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handler.handleCommentLinkTap(
                context,
                'https://news.ycombinator.com/item?id=1',
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.length, 2);
      expect(find.text('article:1'), findsOneWidget);
      expect(hnMatchCalls, 0);
    });

    testWidgets('verified match opens the in-app discussion',
        (WidgetTester tester) async {
      final observer = TestNavigatorObserver();
      final openSpy = UrlOpenerSpy();
      final match = _storyItem(42); // https://example.com/42
      final handler = LinkHandler(
        fetchItem: (id) async => null,
        openUrl: openSpy.call,
        buildArticle: (titledItem, _) => Text('article:${titledItem.id}'),
        findHnMatch: (url) async => match,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handler.handleCommentLinkTap(
                context,
                'https://example.com/42?ref=comment',
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.length, 2);
      expect(find.text('article:42'), findsOneWidget);
      expect(openSpy.opened, isEmpty);
    });

    testWidgets('no verified match falls back to opening the link externally',
        (WidgetTester tester) async {
      final openSpy = UrlOpenerSpy();
      final handler = LinkHandler(
        fetchItem: (id) async => null,
        openUrl: openSpy.call,
        findHnMatch: (url) async => _storyItem(99), // https://example.com/99
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handler.handleCommentLinkTap(
                context,
                'https://different.com/page',
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(openSpy.opened.single.toString(), 'https://different.com/page');
    });

    testWidgets('a lookup error falls back to opening the link externally',
        (WidgetTester tester) async {
      final openSpy = UrlOpenerSpy();
      final handler = LinkHandler(
        fetchItem: (id) async => null,
        openUrl: openSpy.call,
        findHnMatch: (url) async => throw Exception('boom'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handler.handleCommentLinkTap(
                context,
                'https://example.com/errors',
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(openSpy.opened.single.toString(), 'https://example.com/errors');
    });

    testWidgets('a timeout falls back to opening the link externally',
        (WidgetTester tester) async {
      final openSpy = UrlOpenerSpy();
      final handler = LinkHandler(
        fetchItem: (id) async => null,
        openUrl: openSpy.call,
        lookupTimeout: const Duration(milliseconds: 10),
        findHnMatch: (url) =>
            Future.delayed(const Duration(milliseconds: 100), () => null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => handler.handleCommentLinkTap(
                context,
                'https://example.com/slow',
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      // Advance past both the timeout and the still-pending inner delay so
      // no timer is left dangling when the test ends.
      await tester.pump(const Duration(milliseconds: 150));

      expect(openSpy.opened.single.toString(), 'https://example.com/slow');
    });

    testWidgets(
        'concurrent taps on different links have independent lookup lifecycles',
        (WidgetTester tester) async {
      // Reset shared state so this test is independent of run order.
      pendingCommentLinkChecks.value = 0;

      final completerA = Completer<ItemWithKids?>();
      final completerB = Completer<ItemWithKids?>();
      final openSpy = UrlOpenerSpy();
      final handler = LinkHandler(
        fetchItem: (id) async => null,
        openUrl: openSpy.call,
        findHnMatch: (url) => url == 'https://a.example.com'
            ? completerA.future
            : completerB.future,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => handler.handleCommentLinkTap(
                      context, 'https://a.example.com'),
                  child: const Text('tapA'),
                ),
                TextButton(
                  onPressed: () => handler.handleCommentLinkTap(
                      context, 'https://b.example.com'),
                  child: const Text('tapB'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(pendingCommentLinkChecks.value, 0);

      await tester.tap(find.text('tapA'));
      await tester.pump();
      expect(pendingCommentLinkChecks.value, 1);

      await tester.tap(find.text('tapB'));
      await tester.pump();
      expect(pendingCommentLinkChecks.value, 2);

      completerA.complete(null);
      await tester.pump();
      expect(pendingCommentLinkChecks.value, 1);
      expect(openSpy.opened.length, 1);

      completerB.complete(null);
      await tester.pump();
      expect(pendingCommentLinkChecks.value, 0);
      expect(openSpy.opened.length, 2);
    });
  });
}
