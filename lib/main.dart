// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/components/hacker_newser_navigation.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/news.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await getCommentsHandler(client: httpClient).init();
  runApp(MyApp(await getNewsApiRetriever()));
}

class MyApp extends StatefulWidget {
  final NewsApi _newsApi;
  const MyApp(this._newsApi, {Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _createNewsPage() {
    return BlocProvider(
      create: (_) =>
          NewsBloc(widget._newsApi)..add(const FetchNews(NewsType.top)),
      child: HackerNewserNavigation(const News()),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.orange;
    return FluentApp(
      title: 'Hacker Newser',
      theme: FluentThemeData.light().createFluentTheme(
          Colors.white, Colors.black, accentColor, accentColor.lightest),
      darkTheme: FluentThemeData.dark().createFluentTheme(
          Colors.black, Colors.white, accentColor, accentColor.darkest),
      themeMode: ThemeMode.system,
      home: _createNewsPage(),
    );
  }
}
