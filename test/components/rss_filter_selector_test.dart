import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/components/rss_filter_selector.dart';
import 'package:hackernews/rss/models/rss_feed.dart';

void main() {
  final feeds = [
    const RssFeedInfo(name: 'Feed A', url: 'https://a.example/rss'),
    const RssFeedInfo(name: 'Feed B', url: 'https://b.example/rss'),
  ];

  testWidgets('tapping a feed chip calls onChanged with the right value',
      (tester) async {
    RssFeedInfo? selected;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: RssFilterSelector(
            selected: allFeedsInfo,
            feeds: feeds,
            onChanged: (feed) => selected = feed,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Feed B'));
    await tester.pump();

    expect(selected, feeds[1]);
  });

  testWidgets('tapping All calls onChanged with allFeedsInfo', (tester) async {
    RssFeedInfo? selected;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: RssFilterSelector(
            selected: feeds[0],
            feeds: feeds,
            onChanged: (feed) => selected = feed,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pump();

    expect(selected, allFeedsInfo);
  });
}
