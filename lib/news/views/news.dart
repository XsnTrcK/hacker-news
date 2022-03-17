import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/image_list_item.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/view_articles.dart';

class News extends StatefulWidget {
  const News({Key? key}) : super(key: key);

  @override
  _NewsState createState() => _NewsState();
}

class _NewsState extends State<News> {
  final _scrollController = ScrollController();
  NewsType _newsType = NewsType.top;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  bool _isBottom() {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom()) context.read<NewsBloc>().add(FetchNews(_newsType));
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        Widget body;
        switch (state.status) {
          case NewsStatus.sucess:
            if (state.news.isEmpty) {
              body = const Center(child: Text('No posts currently available'));
            }
            body = material.RefreshIndicator(
              onRefresh: () async =>
                  context.read<NewsBloc>().add(RefreshNews(_newsType)),
              child: ListView.separated(
                itemCount: state.news.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => ViewArticles(
                        state.news,
                        initialIndex: index,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ImageListItem(
                      state.news[index],
                      maxHeight: 100,
                    ),
                  ),
                ),
                controller: _scrollController,
              ),
            );
            break;
          case NewsStatus.failure:
            body = const Center(child: Text('Failed to fetch posts'));
            break;
          case NewsStatus.initial:
          default:
            body = const Center(child: ProgressBar());
            break;
        }
        return Column(
          children: [
            Expanded(child: body),
            PillButtonBar(
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
                _newsType = _getNewsType(index);
                context.read<NewsBloc>().add(FetchNews(_newsType));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}
