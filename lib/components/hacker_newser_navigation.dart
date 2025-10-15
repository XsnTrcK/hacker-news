import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/highlight_container.dart';
import 'package:hackernews/components/pill_button.dart';
import 'package:hackernews/menu/menu.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';

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

  _onPressed(NewsType newsType) async {
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

  Widget _buildBottomNav() {
    return Row(
      children: [
        Expanded(
          child: HighlightContainer(
            isSelected: _selectedIndex == 0,
            child: IconButton(
              style: ButtonStyle(
                iconSize: WidgetStateProperty.all(20),
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 10)),
              ),
              icon: const Icon(FluentIcons.collapse_menu),
              onPressed: () async {
                setState(() => _selectedIndex = 0);
                await widget._pageController.animateToPage(_selectedIndex,
                    duration: const Duration(seconds: 1),
                    curve: Curves.fastLinearToSlowEaseIn);
              },
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: HighlightContainer(
            isSelected: _selectedIndex == 1,
            child: CommandBar(
              overflowBehavior: CommandBarOverflowBehavior.scrolling,
              primaryItems: [
                PillButtonBarItem(
                  item: const Text("Top"),
                  onPressed: () => _onPressed(NewsType.top),
                  selected: newsTypeSelected(NewsType.top),
                ),
                PillButtonBarItem(
                  item: const Text("Show"),
                  onPressed: () => _onPressed(NewsType.show),
                  selected: newsTypeSelected(NewsType.show),
                ),
                PillButtonBarItem(
                  item: const Text("Ask"),
                  onPressed: () => _onPressed(NewsType.ask),
                  selected: newsTypeSelected(NewsType.ask),
                ),
                PillButtonBarItem(
                  item: const Text("Job"),
                  onPressed: () => _onPressed(NewsType.job),
                  selected: newsTypeSelected(NewsType.job),
                ),
                PillButtonBarItem(
                  item: const Text("New"),
                  onPressed: () => _onPressed(NewsType.newStories),
                  selected: newsTypeSelected(NewsType.newStories),
                ),
                PillButtonBarItem(
                  item: const Text("Best"),
                  onPressed: () => _onPressed(NewsType.best),
                  selected: newsTypeSelected(NewsType.best),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0),
      content: ColorfulSafeArea(
        top: false,
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(child: _createBody()),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }
}
