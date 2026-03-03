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
}
