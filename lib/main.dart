// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/comments/bloc/comment_bloc.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/views/news.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';

void main() async {
  await Hive.initFlutter();
  var httpClient = Client();
  var commentsApi = CommentsApiRetriever(httpClient);
  var newsApi = NewsApiRetriever(httpClient, commentsApi);
  runApp(MyApp(newsApi, commentsApi));
}

class MyApp extends StatelessWidget {
  final NewsApi _newsApi;
  final CommentsApi _commentsApi;
  const MyApp(this._newsApi, this._commentsApi, {Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        accentColor: Colors.blue,
      ),
      darkTheme: ThemeData(
        accentColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode
          .dark, // Figure out how to set theme based on system and at runtime
      home: SafeArea(
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => NewsBloc(_newsApi)..add(FetchNews()),
            ),
            BlocProvider(create: (_) => CommentBloc(_commentsApi)),
          ],
          child: const News(),
        ),
      ),
    );
  }
}
