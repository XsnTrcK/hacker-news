import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:hackernews/news/bloc/news_state.dart';

/// HN category filter (Top/New/Best/Ask/Show/Jobs): a horizontal scrollable
/// chip row.
class HnTypeSelector extends StatelessWidget {
  final NewsType selected;
  final ValueChanged<NewsType> onChanged;

  const HnTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const types = [
    (NewsType.top, 'Top'),
    (NewsType.newStories, 'New'),
    (NewsType.best, 'Best'),
    (NewsType.ask, 'Ask'),
    (NewsType.show, 'Show'),
    (NewsType.job, 'Jobs'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: types.map((entry) {
            final (type, label) = entry;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(label),
                selected: selected == type,
                onSelected: (_) => onChanged(type),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
