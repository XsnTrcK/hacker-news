import 'dart:developer';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/image_list_item.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/news/views/display_article.dart';
import 'package:hackernews/news/views/view_articles.dart';

class News extends StatefulWidget {
  const News({Key? key}) : super(key: key);

  @override
  _NewsState createState() => _NewsState();
}

class _NewsState extends State<News> {
  final _scrollController = ScrollController();

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
    if (_isBottom()) context.read<NewsBloc>().add(FetchNews());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        switch (state.status) {
          case NewsStatus.sucess:
            if (state.news.isEmpty) {
              return const Center(child: Text('No posts currently available'));
            }
            return ListView.separated(
              itemCount: state.news.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, index) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  FluentPageRoute(
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
            );
          case NewsStatus.failure:
            return const Center(child: Text('Failed to fetch posts'));
          case NewsStatus.initial:
          default:
            return const Center(child: ProgressBar());
        }
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
