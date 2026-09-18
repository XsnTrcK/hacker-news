import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:hackernews/rss/models/rss_feed.dart';

/// RSS feed filter (All + one per configured feed): a horizontal scrollable
/// chip row.
class RssFilterSelector extends StatelessWidget {
  final RssFeedInfo selected;
  final List<RssFeedInfo> feeds;
  final ValueChanged<RssFeedInfo> onChanged;

  const RssFilterSelector({
    super.key,
    required this.selected,
    required this.feeds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final chips = [
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: const Text('All'),
          selected: selected == allFeedsInfo,
          onSelected: (_) => onChanged(allFeedsInfo),
        ),
      ),
      ...feeds.map((feed) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(feed.name),
              selected: selected.url == feed.url,
              onSelected: (_) => onChanged(feed),
            ),
          )),
    ];

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: chips),
      ),
    );
  }
}
