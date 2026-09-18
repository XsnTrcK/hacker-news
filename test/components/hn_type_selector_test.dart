import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/components/hn_type_selector.dart';
import 'package:hackernews/news/bloc/news_state.dart';

void main() {
  testWidgets('tapping a chip calls onChanged with the right value',
      (tester) async {
    NewsType? selected;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: HnTypeSelector(
            selected: NewsType.top,
            onChanged: (type) => selected = type,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Best'));
    await tester.pump();

    expect(selected, NewsType.best);
  });
}
