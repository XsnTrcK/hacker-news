import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/labeled_icon_button.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/news.dart';

class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String _selectedView = "menu";

  Widget _createNewsPage() {
    return FutureBuilder(
      future: getSavedArticlesRetriever(),
      builder: (context, AsyncSnapshot<SavedArticlesRetriever> snapshot) {
        if (snapshot.hasData) {
          return BlocProvider(
            create: (_) =>
                NewsBloc(snapshot.data!)..add(const FetchNews(NewsType.top)),
            child: const News(),
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text('Unable to view saved articles'));
        } else {
          return const Center(child: ProgressBar());
        }
      },
    );
  }

  Widget _createMenuPage(BuildContext context, Typography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
          child: Text(
            "Hacker Newser",
            textAlign: TextAlign.start,
            style: typography.display,
          ),
        ),
        LabeledIconButton(
          onPressed: () => setState(() => _selectedView = "savedArticles"),
          icon: FluentIcons.single_bookmark_solid,
          label: "Saved Articles",
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    switch (_selectedView) {
      case "savedArticles":
        return _createNewsPage();
      case "menu":
      default:
        return _createMenuPage(context, typography);
    }
  }
}
