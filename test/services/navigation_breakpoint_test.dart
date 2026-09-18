import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/services/navigation_breakpoint.dart';

void main() {
  Future<NavigationLayoutMode> modeAtWidth(
      WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late NavigationLayoutMode mode;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          mode = NavigationBreakpoint.of(context);
          return const SizedBox();
        }),
      ),
    );
    return mode;
  }

  testWidgets('reports compact below the 600dp threshold', (tester) async {
    final mode = await modeAtWidth(tester, 599);
    expect(mode, NavigationLayoutMode.compact);
  });

  testWidgets('reports wide at the 600dp threshold', (tester) async {
    final mode = await modeAtWidth(tester, 600);
    expect(mode, NavigationLayoutMode.wide);
  });

  testWidgets('reports wide above the 600dp threshold', (tester) async {
    final mode = await modeAtWidth(tester, 900);
    expect(mode, NavigationLayoutMode.wide);
  });
}
