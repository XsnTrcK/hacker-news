import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/components/filter_fab.dart';

void main() {
  testWidgets('shows the current selection as its label', (tester) async {
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: FilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Best',
            options: const [
              FilterFabOption('top', 'Top'),
              FilterFabOption('best', 'Best'),
            ],
            isSelected: (value) => value == 'best',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('filter_fab_trigger')),
        matching: find.text('Best'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the FAB then an option calls onChanged with the right value',
      (tester) async {
    String? selected;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: FilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Top',
            options: const [
              FilterFabOption('top', 'Top'),
              FilterFabOption('best', 'Best'),
              FilterFabOption('ask', 'Ask'),
            ],
            isSelected: (value) => value == 'top',
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter_fab_trigger')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ask')));
    await tester.pumpAndSettle();

    expect(selected, 'ask');
  });

  testWidgets('dismissing without picking an option does not call onChanged',
      (tester) async {
    var called = false;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: FilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Top',
            options: const [
              FilterFabOption('top', 'Top'),
              FilterFabOption('best', 'Best'),
            ],
            isSelected: (value) => value == 'top',
            onChanged: (_) => called = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter_fab_trigger')));
    await tester.pumpAndSettle();

    // Tap outside the fanned-out options (top-left corner) to dismiss them.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });

  _dropdownFilterFabTests();
}

void _dropdownFilterFabTests() {
  testWidgets('DropdownFilterFab shows the current selection as its label',
      (tester) async {
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: DropdownFilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Best',
            options: const [
              FilterFabOption('top', 'Top'),
              FilterFabOption('best', 'Best'),
            ],
            isSelected: (value) => value == 'best',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('filter_fab_trigger')),
        matching: find.text('Best'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'DropdownFilterFab: tapping the FAB then an option calls onChanged with the right value',
      (tester) async {
    String? selected;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: DropdownFilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Top',
            options: const [
              FilterFabOption('top', 'Top'),
              FilterFabOption('best', 'Best'),
              FilterFabOption('ask', 'Ask'),
            ],
            isSelected: (value) => value == 'top',
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter_fab_trigger')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    expect(selected, 'ask');
  });

  testWidgets(
      'DropdownFilterFab: dismissing without picking an option does not call onChanged',
      (tester) async {
    var called = false;
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: DropdownFilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Top',
            options: const [
              FilterFabOption('top', 'Top'),
              FilterFabOption('best', 'Best'),
            ],
            isSelected: (value) => value == 'top',
            onChanged: (_) => called = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter_fab_trigger')));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });

  testWidgets(
      'DropdownFilterFab: a long option list builds without error and stays tappable',
      (tester) async {
    String? selected;
    final options = [
      for (var i = 0; i < 30; i++) FilterFabOption('feed$i', 'Feed $i'),
    ];
    await tester.pumpWidget(
      fluent.FluentApp(
        home: Scaffold(
          body: DropdownFilterFab<String>(
            icon: Icons.filter_list,
            selectedLabel: 'Feed 0',
            options: options,
            isSelected: (value) => value == 'feed0',
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter_fab_trigger')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Feed 1'));
    await tester.pumpAndSettle();

    expect(selected, 'feed1');
  });
}
