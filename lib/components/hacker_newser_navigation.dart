import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hackernews/menu/menu.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:flutter/material.dart';
import 'package:hackernews/store/settings_store.dart';

class HackerNewserNavigation extends StatefulWidget {
  final Widget body;
  final PageController _pageController = PageController(initialPage: 1);

  HackerNewserNavigation(this.body, {super.key});

  @override
  State<HackerNewserNavigation> createState() => _HackerNewserNavigationState();
}

class _HackerNewserNavigationState extends State<HackerNewserNavigation> {
  NewsType _newsType = NewsType.top;
  int _selectedIndex = 1;

  Future<void> _onPressed(NewsType newsType) async {
    setState(() {
      _selectedIndex = 1;
      _newsType = newsType;
    });
    context.read<NewsBloc>().add(FetchNews(_newsType));
    await widget._pageController.animateToPage(_selectedIndex,
        duration: const Duration(seconds: 1),
        curve: Curves.fastLinearToSlowEaseIn);
  }

  bool newsTypeSelected(NewsType newsType) {
    return newsType == _newsType;
  }

  Widget _buildFABText() {
    switch (_newsType) {
      case NewsType.top:
        return const Text("Top");
      case NewsType.show:
        return const Text("Show");
      case NewsType.ask:
        return const Text("Ask");
      case NewsType.job:
        return const Text("Job");
      case NewsType.newStories:
        return const Text("New");
      case NewsType.best:
        return const Text("Best");
    }
  }

  Widget _createBody() {
    return PageView(
      controller: widget._pageController,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      children: [Menu(key: UniqueKey()), widget.body],
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
        child: _createBody(),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: settings.fabPosition == ExpandableFabPos.center
            ? ExpandableFabType.fan
            : ExpandableFabType.up,
        distance: settings.fabPosition == ExpandableFabPos.center ? 100 : 50,
        fanAngle: settings.fabPosition == ExpandableFabPos.center ? 180 : 90,
        pos: settings.fabPosition,
        childrenAnimation: ExpandableFabAnimation.none,
        openButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: _buildFABText(),
        ),
        children: [
          FloatingActionButton.small(
            onPressed: () => _onPressed(NewsType.top),
            child: const Text("Top"),
          ),
          FloatingActionButton.small(
            onPressed: () => _onPressed(NewsType.show),
            child: const Text("Show"),
          ),
          FloatingActionButton.small(
            onPressed: () => _onPressed(NewsType.ask),
            child: const Text("Ask"),
          ),
          FloatingActionButton.small(
            onPressed: () => _onPressed(NewsType.job),
            child: const Text("Job"),
          ),
          FloatingActionButton.small(
            onPressed: () => _onPressed(NewsType.newStories),
            child: const Text("New"),
          ),
          FloatingActionButton.small(
            onPressed: () => _onPressed(NewsType.best),
            child: const Text("Best"),
          ),
        ],
      ),
    );
  }
}
