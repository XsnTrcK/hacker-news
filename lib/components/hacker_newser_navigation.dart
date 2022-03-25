import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/highlight_container.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';

class HackerNewserNavigation extends StatefulWidget {
  final Widget body;

  const HackerNewserNavigation(this.body, {Key? key}) : super(key: key);

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
        HighlightContainer(
          isSelected: _selectedIndex == 0,
          width: 40,
          child: IconButton(
            style: ButtonStyle(
              iconSize: ButtonState.all(20),
              padding: ButtonState.all(
                  const EdgeInsets.symmetric(vertical: 13, horizontal: 10)),
            ),
            icon: const Icon(FluentIcons.collapse_menu),
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
        ),
        Expanded(
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
              onChanged: (index) {
                setState(() {
                  _selectedIndex = 1;
                  _newsType = _getNewsType(index);
                });
                context.read<NewsBloc>().add(FetchNews(_newsType));
              },
            ),
          ),
        ),
        HighlightContainer(
          isSelected: _selectedIndex == 2,
          width: 40,
          child: IconButton(
            style: ButtonStyle(
              iconSize: ButtonState.all(20),
              padding: ButtonState.all(
                  const EdgeInsets.symmetric(vertical: 13, horizontal: 10)),
            ),
            icon: const Icon(FluentIcons.account_management),
            onPressed: () => setState(() => _selectedIndex = 2),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fluentTheme = FluentTheme.of(context);
    return Column(
      children: [
        Expanded(child: widget.body),
        _buildBottomNav(fluentTheme),
      ],
    );
  }
}
