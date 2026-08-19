import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/components/image_list_item.dart';
import 'package:hackernews/news/views/view_articles.dart';
import 'package:hackernews/search/bloc/search_bloc.dart';
import 'package:hackernews/search/bloc/search_events.dart';
import 'package:hackernews/search/bloc/search_state.dart';
import 'package:hackernews/services/theme_extensions.dart';

class SearchPage extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController queryController;

  const SearchPage(
      {super.key, required this.focusNode, required this.queryController});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin<SearchPage> {
  static const _debounceDuration = Duration(milliseconds: 350);

  final _scrollController = ScrollController();
  Timer? _debounce;

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
      context.read<SearchBloc>().add(const SearchNextPageRequested());
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Widget _buildMessage(String message, Typography typography) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          style: typography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody(SearchState state, Typography typography) {
    switch (state.status) {
      case SearchStatus.initial:
        return _buildMessage('Search Hacker News stories', typography);
      case SearchStatus.loading:
        return const Center(child: ProgressRing());
      case SearchStatus.empty:
        return _buildMessage('No results for "${state.query}"', typography);
      case SearchStatus.failure:
        return _buildMessage(
            'Search failed. Try editing your query.', typography);
      case SearchStatus.success:
        return ListView.separated(
          controller: _scrollController,
          itemCount: state.results.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ViewArticles(
                  state.results,
                  initialIndex: index,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ImageListItem(
                state.results[index],
                maxHeight: 100,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = FluentTheme.of(context);
    final typography = theme.dynamicTypography;
    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) => _buildBody(state, typography),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            child: TextBox(
              controller: widget.queryController,
              focusNode: widget.focusNode,
              placeholder: 'Search stories',
              onChanged: _onQueryChanged,
            ),
          ),
        ],
      ),
    );
  }
}
