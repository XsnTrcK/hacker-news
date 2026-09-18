import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/image_list_item.dart';
import 'package:hackernews/news/bloc/news_bloc.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hackernews/news/views/view_articles.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> with AutomaticKeepAliveClientMixin<News> {
  final _scrollController = ScrollController();
  NewsType _newsType = NewsType.top;
  FeedMode _feedMode = FeedMode.all;
  RssFeedInfo _rssFeedFilter = allFeedsInfo;

  @override
  bool get wantKeepAlive => true;

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
    if (_isBottom()) {
      context.read<NewsBloc>().add(FetchNews(
            _newsType,
            feedMode: _feedMode,
            rssFeedFilter: _rssFeedFilter,
          ));
    }
  }

  Future<void> _refresh() async {
    context.read<NewsBloc>().add(RefreshNews(
          _newsType,
          feedMode: _feedMode,
          rssFeedFilter: _rssFeedFilter,
        ));
  }

  // A bare Center isn't scrollable, so RefreshIndicator can't detect the
  // pull gesture on it — wrap it in an always-scrollable ListView instead.
  Widget _refreshableMessage(String message) {
    return material.RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const material.AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(child: Text(message)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        _newsType = state.newsType;
        _feedMode = state.feedMode;
        _rssFeedFilter = state.rssFeedFilter;
        switch (state.status) {
          case NewsStatus.sucess:
            if (state.news.isEmpty) {
              return _refreshableMessage('No posts currently available');
            }
            return material.RefreshIndicator(
              onRefresh: _refresh,
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
          case NewsStatus.failure:
            return _refreshableMessage('Failed to fetch posts');
          case NewsStatus.initial:
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
