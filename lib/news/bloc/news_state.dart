import 'package:equatable/equatable.dart';
import 'package:hackernews/models/item.dart';

enum NewsStatus { initial, sucess, failure }
enum NewsType { top, newStories, best, ask, show, job }

class NewsState extends Equatable {
  final NewsStatus status;
  final List<TitledItem> news;
  final bool hasReachedMax;
  final NewsType newsType;

  const NewsState({
    this.status = NewsStatus.initial,
    this.news = const <TitledItem>[],
    this.hasReachedMax = false,
    this.newsType = NewsType.top,
  });

  NewsState copyWith({
    NewsStatus? status,
    List<TitledItem>? news,
    bool? hasReachedMax,
    NewsType? newsType,
  }) {
    return NewsState(
      status: status ?? this.status,
      news: news ?? this.news,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      newsType: newsType ?? this.newsType,
    );
  }

  @override
  List<Object?> get props => [status, news, hasReachedMax, newsType];
}
