import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/labeled_icon_button.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/news.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:hackernews/settings/views/settings.dart';

class Menu extends StatelessWidget {
  const Menu({Key? key}) : super(key: key);

  Widget _createNewsPage() {
    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0),
      content: BlocProvider(
        create: (_) => NewsBloc(savedArticlesRetriever)
          ..add(const FetchNews(NewsType.top)),
        child: const News(),
      ),
    );
  }

  void Function() _handleClick(
      BuildContext context, Widget Function() builder) {
    final theme = FluentTheme.of(context);
    return () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ColorfulSafeArea(
              color: theme.scaffoldBackgroundColor,
              child: builder(),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).dynamicTypography;
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
          onPressed: _handleClick(context, () => _createNewsPage()),
          icon: FluentIcons.single_bookmark_solid,
          label: "Saved Articles",
        ),
        const Divider(),
        LabeledIconButton(
          onPressed: _handleClick(context, () => const Settings()),
          icon: FluentIcons.settings,
          label: "Settings",
        ),
        const Divider(),
      ],
    );
  }
}
