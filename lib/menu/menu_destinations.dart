import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/news.dart';
import 'package:hackernews/rss/bloc/rss_feeds_bloc.dart';
import 'package:hackernews/rss/views/rss_feeds_page.dart';
import 'package:hackernews/settings/views/settings.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// A single Menu link, shared between the compact `Menu` page and the
/// wide-mode navigation rail. `builder` returns the destination's content,
/// unwrapped by any route/page chrome so it can be embedded either as a
/// pushed page (compact) or a rail content pane (wide).
class MenuDestination {
  final IconData icon;
  final String label;
  final Widget Function() builder;

  const MenuDestination({
    required this.icon,
    required this.label,
    required this.builder,
  });
}

Widget _savedArticlesPage() {
  return ScaffoldPage(
    padding: const EdgeInsets.symmetric(vertical: 0),
    content: BlocProvider(
      create: (_) => NewsBloc(savedArticlesRetriever)
        ..add(const FetchNews(NewsType.top)),
      child: const News(),
    ),
  );
}

Widget _rssFeedsPage() {
  return BlocProvider(
    create: (_) => RssFeedsBloc(),
    child: const RssFeedsPage(),
  );
}

Widget _settingsPage() => const Settings();

final List<MenuDestination> menuDestinations = [
  MenuDestination(
    icon: FluentIcons.single_bookmark_solid,
    label: 'Saved Articles',
    builder: _savedArticlesPage,
  ),
  MenuDestination(
    icon: MdiIcons.rss,
    label: 'RSS Feeds',
    builder: _rssFeedsPage,
  ),
  MenuDestination(
    icon: FluentIcons.settings,
    label: 'Settings',
    builder: _settingsPage,
  ),
];
