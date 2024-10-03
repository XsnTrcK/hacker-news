// ignore_for_file: import_of_legacy_library_into_null_safe

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
import 'package:hackernews/settings/bloc/settings_bloc.dart';
import 'package:hackernews/settings/bloc/settings_state.dart';
import 'package:hackernews/store/settings_store.dart';
import 'package:hackernews/store/store.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await getCommentsHandler(client: httpClient).init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _createNewsPage() {
    return FutureBuilder(
      future: Future.wait(
        [initSettings(), initNewsStore()],
      ),
      builder: (context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasData) {
          return BlocProvider(
            create: (_) =>
                NewsBloc(newsApiRetriever)..add(const FetchNews(NewsType.top)),
            child: HackerNewserNavigation(const News()),
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text('Unable to initialize app'));
        } else {
          return const Center(child: ProgressBar());
        }
      },
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.orange;
    return BlocProvider(
      create: (_) => SettingsBloc(),
      child: BlocBuilder<SettingsBloc, SettingsBlocUpdated>(
        builder: (context, state) {
          return FluentApp(
            title: 'Hacker Newser',
            theme: FluentThemeData.light().createFluentTheme(
                Colors.white, Colors.black, accentColor, accentColor.lightest),
            darkTheme: FluentThemeData.dark().createFluentTheme(
                Colors.black, Colors.white, accentColor, accentColor.darkest),
            themeMode: ThemeMode.system,
            home: _createNewsPage(),
          );
        },
      ),
    );
  }
}
