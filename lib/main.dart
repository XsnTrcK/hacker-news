// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/news.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';

extension FluentTheming on ThemeData {
  Color _applyOpacity(Color color, Set<ButtonStates> states) {
    return color.withOpacity(
      states.isPressing
          ? 0.925
          : states.isFocused
              ? 0.4
              : states.isHovering
                  ? 0.85
                  : 1.0,
    );
  }

  ThemeData createFluentTheme(
    Color mainColor,
    AccentColor accentColor,
    Color highlightColor,
  ) {
    return copyWith(
      accentColor: accentColor,
      scaffoldBackgroundColor: mainColor,
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: mainColor,
        highlightColor: highlightColor,
      ),
      pillButtonBarTheme: PillButtonBarThemeData(
        backgroundColor: mainColor,
        selectedColor: ButtonState.resolveWith(
          (states) => _applyOpacity(highlightColor, states),
        ),
      ),
    );
  }
}

void main() async {
  await Hive.initFlutter();
  var httpClient = Client();
  await getCommentsHandler(client: httpClient).init();
  var newsApi = NewsApiRetriever(httpClient);
  await newsApi.init();
  runApp(MyApp(newsApi));
}

class MyApp extends StatefulWidget {
  final NewsApi _newsApi;
  const MyApp(this._newsApi, {Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  Widget _createNewsPage() {
    return BlocProvider(
      create: (_) =>
          NewsBloc(widget._newsApi)..add(const FetchNews(NewsType.top)),
      child: const News(),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.orange;
    return FluentApp(
      title: 'Hacker Newser',
      theme: ThemeData.light()
          .createFluentTheme(Colors.white, accentColor, accentColor.lightest),
      darkTheme: ThemeData.dark()
          .createFluentTheme(Colors.black, accentColor, accentColor.darkest),
      themeMode: ThemeMode.system,
      home: ColorfulSafeArea(
        color: Colors.black,
        child: NavigationView(
          content: NavigationBody.builder(
            index: _currentIndex,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _createNewsPage();
                default:
                  return Text("Invalid menu item selected: $index");
              }
            },
          ),
          pane: NavigationPane(
            displayMode: PaneDisplayMode.top,
            selected: _currentIndex,
            onChanged: (index) => setState(() => _currentIndex = index),
            header: const Text(
              "Hacker Newser",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            items: [
              PaneItem(
                icon: const Icon(FluentIcons.news),
                title: const Text("News"),
              ),
            ],
            footerItems: [
              PaneItem(
                icon: const Icon(FluentIcons.settings),
                title: const Text("Settings"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
