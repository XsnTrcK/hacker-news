import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hackernews/components/filter_fab.dart';
import 'package:hackernews/components/hn_type_selector.dart';
import 'package:hackernews/components/nav_destination.dart';
import 'package:hackernews/components/rss_filter_selector.dart';
import 'package:hackernews/menu/menu.dart';
import 'package:hackernews/menu/menu_destinations.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hackernews/rss/store/rss_feeds_store.dart';
import 'package:hackernews/search/apis/algolia_story_search_api.dart';
import 'package:hackernews/search/bloc/search_bloc.dart';
import 'package:hackernews/search/views/search_page.dart';
import 'package:hackernews/services/navigation_breakpoint.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

typedef _WidePane = ({bool showingSearch, int? menuIndex, FeedMode feedMode});

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

  // Wide-mode-only: which rail content pane is showing, plus a back-stack of
  // previously shown panes so the system back gesture/button steps through
  // rail navigation instead of exiting. Compact mode tracks its current page
  // via `widget._pageController` instead.
  bool _wideShowingSearch = false;
  int? _wideMenuIndex;
  final List<_WidePane> _wideHistory = [];

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
    if (widget._pageController.hasClients) {
      widget._pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

  _WidePane get _currentWidePane => (
        showingSearch: _wideShowingSearch,
        menuIndex: _wideMenuIndex,
        feedMode: _feedMode,
      );

  // Applies a pane without touching `_wideHistory` — used both for forward
  // navigation (after the caller pushes history) and for back navigation
  // (where the popped entry should not be re-pushed).
  void _applyWidePane(_WidePane pane) {
    setState(() {
      _wideShowingSearch = pane.showingSearch;
      _wideMenuIndex = pane.menuIndex;
      _feedMode = pane.feedMode;
      if (pane.feedMode != FeedMode.rss) _rssFeedFilter = allFeedsInfo;
    });
    if (pane.showingSearch) {
      if (_swipeSearchQueryController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _swipeSearchFocusNode.requestFocus());
      }
    } else {
      _swipeSearchFocusNode.unfocus();
    }
    if (!pane.showingSearch && pane.menuIndex == null) {
      _dispatchFetch();
    }
  }

  void _selectWidePane(_WidePane pane) {
    if (pane == _currentWidePane) return;
    _wideHistory.add(_currentWidePane);
    _applyWidePane(pane);
  }

  void _goWideBack() {
    if (_wideHistory.isEmpty) return;
    _applyWidePane(_wideHistory.removeLast());
  }

  void _goWideHome() {
    _wideHistory.clear();
    _applyWidePane((showingSearch: false, menuIndex: null, feedMode: _feedMode));
  }

  static final _feedModeEntries = [
    (
      icon: Icons.newspaper_outlined,
      selectedIcon: Icons.newspaper,
      label: 'All',
      mode: FeedMode.all,
    ),
    (
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      label: 'Hacker News',
      mode: FeedMode.hn,
    ),
    (icon: MdiIcons.rssBox, selectedIcon: null, label: 'RSS', mode: FeedMode.rss),
  ];

  List<NavDestination> _feedModeDestinations() => [
        for (final e in _feedModeEntries)
          NavDestination(
            icon: e.icon,
            selectedIcon: e.selectedIcon,
            label: e.label,
            onSelected: () => _onFeedModeChanged(e.mode),
          ),
      ];

  List<NavDestination> _wideDestinations(bool hasRss) => [
        if (hasRss)
          for (final e in _feedModeEntries)
            NavDestination(
              icon: e.icon,
              selectedIcon: e.selectedIcon,
              label: e.label,
              onSelected: () => _selectWidePane(
                  (showingSearch: false, menuIndex: null, feedMode: e.mode)),
            ),
        NavDestination(
          icon: Icons.search,
          label: 'Search',
          onSelected: () => _selectWidePane(
              (showingSearch: true, menuIndex: null, feedMode: _feedMode)),
        ),
        for (var i = 0; i < menuDestinations.length; i++)
          NavDestination(
            icon: menuDestinations[i].icon,
            label: menuDestinations[i].label,
            onSelected: () => _selectWidePane(
                (showingSearch: false, menuIndex: i, feedMode: _feedMode)),
          ),
      ];

  int? _wideSelectedIndex(bool hasRss) {
    final feedCount = hasRss ? 3 : 0;
    if (_wideShowingSearch) return feedCount;
    if (_wideMenuIndex != null) return feedCount + 1 + _wideMenuIndex!;
    if (!hasRss) return null;
    return switch (_feedMode) {
      FeedMode.all => 0,
      FeedMode.hn => 1,
      FeedMode.rss => 2,
    };
  }

  Widget _buildNewsPage() {
    return Column(
      children: [
        Expanded(child: widget.body),
        if (_feedMode == FeedMode.hn)
          HnTypeSelector(selected: _hnNewsType, onChanged: _onHnTypeChanged),
        if (_feedMode == FeedMode.rss && rssFeedsStore.feeds.isNotEmpty)
          RssFilterSelector(
            selected: _rssFeedFilter,
            feeds: rssFeedsStore.feeds,
            onChanged: _onRssFeedFilterChanged,
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final destinations = _feedModeDestinations();
    return NavigationBar(
      selectedIndex: switch (_feedMode) {
        FeedMode.all => 0,
        FeedMode.hn => 1,
        FeedMode.rss => 2,
      },
      onDestinationSelected: (index) => destinations[index].onSelected(),
      destinations: [
        for (final d in destinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: d.selectedIcon != null ? Icon(d.selectedIcon) : null,
            label: d.label,
          ),
      ],
    );
  }

  Widget _buildCompactLayout(fluent.FluentThemeData theme, bool hasRss) {
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
            _buildNewsPage(),
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
      bottomNavigationBar: hasRss ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _wideContent(fluent.FluentThemeData theme) {
    if (_wideShowingSearch) {
      return ColorfulSafeArea(
        color: theme.scaffoldBackgroundColor,
        child: BlocProvider.value(
          value: _swipeSearchBloc,
          child: SearchPage(
            focusNode: _swipeSearchFocusNode,
            queryController: _swipeSearchQueryController,
          ),
        ),
      );
    }
    if (_wideMenuIndex != null) {
      return menuDestinations[_wideMenuIndex!].builder();
    }
    return widget.body;
  }

  Widget _buildNavigationRail(fluent.FluentThemeData theme, bool hasRss) {
    final destinations = _wideDestinations(hasRss);
    return NavigationRail(
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedIndex: _wideSelectedIndex(hasRss),
      labelType: NavigationRailLabelType.all,
      minWidth: 96,
      leading: GestureDetector(
        onTap: _goWideHome,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 88,
            child: Text(
              'Hacker Newser',
              textAlign: TextAlign.center,
              style: theme.dynamicTypography.caption,
            ),
          ),
        ),
      ),
      onDestinationSelected: (index) => destinations[index].onSelected(),
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon ?? d.icon),
            label: Text(d.label),
          ),
      ],
    );
  }

  // The HN/RSS category filter in wide mode: only relevant while viewing
  // News content in a filterable feed mode (mirrors the old `showFilters`
  // condition). `FilterFab` (HN) is built on `flutter_expandable_fab`,
  // which needs its own `floatingActionButtonLocation` to position itself
  // correctly; `DropdownFilterFab` (RSS) is a plain FAB and needs the
  // standard corner location instead — using ExpandableFab's location for
  // it mispositions it (that location class is coupled to ExpandableFab's
  // own internal geometry, not a general-purpose FAB position).
  ({Widget? fab, FloatingActionButtonLocation location}) _buildFilterFab() {
    if (_wideShowingSearch || _wideMenuIndex != null) {
      return (fab: null, location: FloatingActionButtonLocation.endFloat);
    }
    if (_feedMode == FeedMode.hn) {
      return (
        fab: FilterFab<NewsType>(
          icon: Icons.filter_list,
          selectedLabel:
              HnTypeSelector.types.firstWhere((e) => e.$1 == _hnNewsType).$2,
          options: [
            for (final e in HnTypeSelector.types) FilterFabOption(e.$1, e.$2),
          ],
          isSelected: (type) => type == _hnNewsType,
          onChanged: _onHnTypeChanged,
        ),
        location: ExpandableFab.location,
      );
    }
    if (_feedMode == FeedMode.rss && rssFeedsStore.feeds.isNotEmpty) {
      return (
        fab: DropdownFilterFab<RssFeedInfo>(
          icon: MdiIcons.rssBox,
          selectedLabel:
              _rssFeedFilter == allFeedsInfo ? 'All' : _rssFeedFilter.name,
          options: [
            const FilterFabOption(allFeedsInfo, 'All'),
            for (final feed in rssFeedsStore.feeds)
              FilterFabOption(feed, feed.name),
          ],
          isSelected: (feed) => feed.url == _rssFeedFilter.url,
          onChanged: _onRssFeedFilterChanged,
        ),
        location: FloatingActionButtonLocation.endFloat,
      );
    }
    return (fab: null, location: FloatingActionButtonLocation.endFloat);
  }

  Widget _buildWideLayout(fluent.FluentThemeData theme, bool hasRss) {
    final filterFab = _buildFilterFab();
    return PopScope(
      canPop: _wideHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goWideBack();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ColorfulSafeArea(
          color: theme.scaffoldBackgroundColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNavigationRail(theme, hasRss),
              const VerticalDivider(width: 1),
              Expanded(child: _wideContent(theme)),
            ],
          ),
        ),
        floatingActionButton: filterFab.fab,
        floatingActionButtonLocation: filterFab.location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final hasRss = rssFeedsStore.feeds.isNotEmpty;
    if (!hasRss) {
      setState(() {
        _feedMode = FeedMode.hn;
      });
      _dispatchFetch();
    }
    return NavigationBreakpoint.of(context) == NavigationLayoutMode.wide
        ? _buildWideLayout(theme, hasRss)
        : _buildCompactLayout(theme, hasRss);
  }
}
