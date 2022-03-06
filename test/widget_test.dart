// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/comments/apis/comments_api.dart';

import 'package:hackernews/main.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:http/http.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    var httpClient = Client();
    var commentApiRetriever = CommentsApiRetriever(httpClient);
    var newsApiRetriever = NewsApiRetriever(httpClient, commentApiRetriever);
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(newsApiRetriever, commentApiRetriever));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
