import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/menu/menu.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hackernews/rss/store/rss_feeds_store.dart';
import 'package:hackernews/search/apis/algolia_story_search_api.dart';
import 'package:hackernews/search/bloc/search_bloc.dart';
import 'package:hackernews/search/views/search_page.dart';
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
  final _swipeSearchBloc = SearchBloc(AlgoliaStorySearchApi(httpClient));
  final _swipeSearchFocusNode = FocusNode();
  final _swipeSearchQueryController = TextEditingController();

  @override
  void dispose() {
    _swipeSearchBloc.close();
    _swipeSearchFocusNode.dispose();
    _swipeSearchQueryController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (page == 2) {
      if (_swipeSearchQueryController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _swipeSearchFocusNode.requestFocus());
      }
    } else {
      _swipeSearchFocusNode.unfocus();
    }
  }

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

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    Widget? bottomNavigationBar;
    if (rssFeedsStore.feeds.isEmpty) {
      setState(() {
        _feedMode = FeedMode.hn;
      });
      _dispatchFetch();
    } else {
      bottomNavigationBar = _buildBottomNavigationBar();
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ColorfulSafeArea(
        top: false,
        color: theme.scaffoldBackgroundColor,
        child: PageView(
          controller: widget._pageController,
          onPageChanged: _onPageChanged,
          children: [
            const Menu(),
            _buildNewsPage(theme),
            ColorfulSafeArea(
              color: theme.scaffoldBackgroundColor,
              child: BlocProvider.value(
                value: _swipeSearchBloc,
                child: SearchPage(
                  focusNode: _swipeSearchFocusNode,
                  queryController: _swipeSearchQueryController,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
