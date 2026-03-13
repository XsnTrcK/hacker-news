import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/menu/menu.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hackernews/rss/store/rss_feeds_store.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HackerNewserNavigation extends StatefulWidget {
  final Widget body;
  final PageController _pageController = PageController(initialPage: 1);

  HackerNewserNavigation(this.body, {super.key});

  @override
  State<HackerNewserNavigation> createState() => _HackerNewserNavigationState();
}

class _HackerNewserNavigationState extends State<HackerNewserNavigation> {
  FeedMode _feedMode = FeedMode.all;
  NewsType _hnNewsType = NewsType.top;
  RssFeedInfo _rssFeedFilter = allFeedsInfo;

  void _onFeedModeChanged(FeedMode mode) {
    setState(() {
      _feedMode = mode;
      if (mode != FeedMode.rss) _rssFeedFilter = allFeedsInfo;
    });
    _dispatchFetch();
    widget._pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onHnTypeChanged(NewsType type) {
    setState(() => _hnNewsType = type);
    _dispatchFetch();
  }

  void _onRssFeedFilterChanged(RssFeedInfo feed) {
    setState(() => _rssFeedFilter = feed);
    _dispatchFetch();
  }

  void _dispatchFetch() {
    context.read<NewsBloc>().add(FetchNews(
          _feedMode == FeedMode.hn ? _hnNewsType : NewsType.top,
          feedMode: _feedMode,
          rssFeedFilter: _rssFeedFilter,
        ));
  }

  Widget _buildHnTypeChips(fluent.FluentThemeData theme) {
    const types = [
      (NewsType.top, 'Top'),
      (NewsType.newStories, 'New'),
      (NewsType.best, 'Best'),
      (NewsType.ask, 'Ask'),
      (NewsType.show, 'Show'),
      (NewsType.job, 'Jobs'),
    ];
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: types.map((entry) {
            final (type, label) = entry;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(label),
                selected: _hnNewsType == type,
                onSelected: (_) => _onHnTypeChanged(type),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRssFilterChips(fluent.FluentThemeData theme) {
    final feeds = rssFeedsStore.feeds;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: const Text('All'),
                selected: _rssFeedFilter == allFeedsInfo,
                onSelected: (_) => _onRssFeedFilterChanged(allFeedsInfo),
              ),
            ),
            ...feeds.map((feed) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(feed.name),
                    selected: _rssFeedFilter.url == feed.url,
                    onSelected: (_) => _onRssFeedFilterChanged(feed),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsPage(fluent.FluentThemeData theme) {
    return Column(
      children: [
        Expanded(child: widget.body),
        if (_feedMode == FeedMode.hn) _buildHnTypeChips(theme),
        if (_feedMode == FeedMode.rss && rssFeedsStore.feeds.isNotEmpty)
          _buildRssFilterChips(theme),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ColorfulSafeArea(
        top: false,
        color: theme.scaffoldBackgroundColor,
        child: PageView(
          controller: widget._pageController,
          children: [
            Menu(key: UniqueKey()),
            _buildNewsPage(theme),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_feedMode) {
          FeedMode.all => 0,
          FeedMode.hn => 1,
          FeedMode.rss => 2,
        },
        onDestinationSelected: (index) => _onFeedModeChanged(switch (index) {
          1 => FeedMode.hn,
          2 => FeedMode.rss,
          _ => FeedMode.all,
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'All',
          ),
          const NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Hacker News',
          ),
          NavigationDestination(
            icon: Icon(MdiIcons.rssBox),
            label: 'RSS',
          ),
        ],
      ),
    );
  }
}
