import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/highlight_container.dart';
import 'package:hackernews/menu/menu.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';

class HackerNewserNavigation extends StatefulWidget {
  final Widget body;
  final PageController _pageController = PageController(initialPage: 1);

  HackerNewserNavigation(this.body, {Key? key}) : super(key: key);

  @override
  State<HackerNewserNavigation> createState() => _HackerNewserNavigationState();
}

class _HackerNewserNavigationState extends State<HackerNewserNavigation> {
  NewsType _newsType = NewsType.top;
  int _selectedIndex = 1;

  NewsType _getNewsType(int selectedItem) {
    switch (selectedItem) {
      case 0:
        return NewsType.top;
      case 1:
        return NewsType.show;
      case 2:
        return NewsType.ask;
      case 3:
        return NewsType.job;
      case 4:
        return NewsType.newStories;
      case 5:
        return NewsType.best;
      default:
        throw Error();
    }
  }

  int _getSelectedIndex(NewsType newsType) {
    switch (newsType) {
      case NewsType.top:
        return 0;
      case NewsType.show:
        return 1;
      case NewsType.ask:
        return 2;
      case NewsType.job:
        return 3;
      case NewsType.newStories:
        return 4;
      case NewsType.best:
        return 5;
    }
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: HighlightContainer(
            isSelected: _selectedIndex == 0,
            child: IconButton(
              style: ButtonStyle(
                iconSize: ButtonState.all(20),
                padding: ButtonState.all(
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
            child: PillButtonBar(
              selected: _getSelectedIndex(_newsType),
              items: const [
                PillButtonBarItem(text: Text("Top")),
                PillButtonBarItem(text: Text("Show")),
                PillButtonBarItem(text: Text("Ask")),
                PillButtonBarItem(text: Text("Job")),
                PillButtonBarItem(text: Text("New")),
                PillButtonBarItem(text: Text("Best")),
              ],
              onChanged: (index) async {
                setState(() {
                  _selectedIndex = 1;
                  _newsType = _getNewsType(index);
                });
                context.read<NewsBloc>().add(FetchNews(_newsType));
                await widget._pageController.animateToPage(_selectedIndex,
                    duration: const Duration(seconds: 1),
                    curve: Curves.fastLinearToSlowEaseIn);
              },
            ),
          ),
        ),
        // Expanded(
        //   child: HighlightContainer(
        //     isSelected: _selectedIndex == 2,
        //     child: IconButton(
        //       style: ButtonStyle(
        //         iconSize: ButtonState.all(20),
        //         padding: ButtonState.all(
        //             const EdgeInsets.symmetric(vertical: 13, horizontal: 10)),
        //       ),
        //       icon: const Icon(FluentIcons.account_management),
        //       onPressed: () => setState(() => _selectedIndex = 2),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _createBody() {
    return PageView(
      controller: widget._pageController,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      children: [const Menu(), widget.body],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fluentTheme = FluentTheme.of(context);
    return Column(
      children: [
        Expanded(child: _createBody()),
        _buildBottomNav(fluentTheme),
      ],
    );
  }
}
