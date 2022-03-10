import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/bloc/news_events.dart';
import 'package:hackernews/news/bloc/news_state.dart';

class NewsBloc extends ThrottledBloc<NewsEvent, NewsState> {
  final NewsApi _newsApi;

  NewsBloc(this._newsApi) : super(const NewsState()) {
    on<FetchNews>(_onFetchNews, transformer: throttleDroppable());
    on<RefreshNews>(_onRefreshNews, transformer: throttleDroppable());
  }

  Future _onFetchNews(FetchNews event, Emitter<NewsState> emit) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == NewsStatus.initial) {
        await _newsApi.refresh();
        final newsItems = await _newsApi.getNews();
        emit(state.copyWith(
          status: NewsStatus.sucess,
          news: newsItems,
          hasReachedMax: false,
        ));
      } else {
        final newsItems = await _newsApi.getNews(offset: state.news.length);
        emit(state.copyWith(
          status: NewsStatus.sucess,
          news: List.of(state.news)..addAll(newsItems),
          hasReachedMax: false,
        ));
      }
    } catch (error) {
      log("Error: $error");
      emit(state.copyWith(status: NewsStatus.failure));
    }
  }

  Future _onRefreshNews(RefreshNews event, Emitter<NewsState> emit) async {
    if (state.hasReachedMax) return;
    try {
      emit(const NewsState());
      await _newsApi.refresh();
      final newsItems = await _newsApi.getNews();
      emit(NewsState(
        status: NewsStatus.sucess,
        news: newsItems,
        hasReachedMax: false,
      ));
    } catch (error) {
      log("Error: $error");
      emit(state.copyWith(status: NewsStatus.failure));
    }
  }
}
