import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/apis/combined_news_api.dart';

class NewsBloc extends ThrottledBloc<NewsEvent, NewsState> {
  final NewsApi _newsApi;

  NewsBloc(this._newsApi) : super(const NewsState()) {
    on<FetchNews>(_onFetchNews, transformer: throttleDroppable());
    on<RefreshNews>(_onRefreshNews, transformer: throttleDroppable());
  }

  void _applyMode(NewsEvent event) {
    if (_newsApi is CombinedNewsApiRetriever) {
      (_newsApi as CombinedNewsApiRetriever)
          .setMode(event.feedMode, rssFeedFilter: event.rssFeedFilter);
    }
  }

  Future _onFetchNews(FetchNews event, Emitter<NewsState> emit) async {
    if (state.hasReachedMax) return;
    try {
      final hasDifferentNewsType = state.newsType != event.newsType;
      final hasDifferentMode = state.feedMode != event.feedMode ||
          state.rssFeedFilter != event.rssFeedFilter;
      if (state.status == NewsStatus.initial ||
          hasDifferentNewsType ||
          hasDifferentMode) {
        if (hasDifferentNewsType || hasDifferentMode) emit(const NewsState());
        _applyMode(event);
        await _newsApi.refresh(event.newsType);
        final newsItems = await _newsApi.getNews(event.newsType);
        emit(NewsState(
          status: NewsStatus.sucess,
          news: newsItems,
          hasReachedMax: false,
          newsType: event.newsType,
          feedMode: event.feedMode,
          rssFeedFilter: event.rssFeedFilter,
        ));
      } else {
        final newsItems =
            await _newsApi.getNews(event.newsType, offset: state.news.length);
        emit(state.copyWith(
          status: NewsStatus.sucess,
          news: List.of(state.news)..addAll(newsItems),
          hasReachedMax: newsItems.isEmpty,
          newsType: event.newsType,
        ));
      }
    } catch (error) {
      log("Error: $error");
      emit(state.copyWith(status: NewsStatus.failure));
    }
  }

  Future _onRefreshNews(RefreshNews event, Emitter<NewsState> emit) async {
    try {
      emit(const NewsState());
      _applyMode(event);
      await _newsApi.refresh(event.newsType);
      final newsItems = await _newsApi.getNews(event.newsType);
      emit(NewsState(
        status: NewsStatus.sucess,
        news: newsItems,
        hasReachedMax: false,
        newsType: event.newsType,
        feedMode: event.feedMode,
        rssFeedFilter: event.rssFeedFilter,
      ));
    } catch (error) {
      log("Error: $error");
      emit(state.copyWith(status: NewsStatus.failure));
    }
  }
}
