import 'package:equatable/equatable.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/rss/models/rss_feed.dart';

enum NewsStatus { initial, sucess, failure }

enum NewsType { top, newStories, best, ask, show, job }

enum FeedMode { all, hn, rss }

class NewsState extends Equatable {
  final NewsStatus status;
  final List<TitledItem> news;
  final bool hasReachedMax;
  final NewsType newsType;
  final FeedMode feedMode;
  final RssFeedInfo? rssFeedFilter;

  const NewsState({
    this.status = NewsStatus.initial,
    this.news = const <TitledItem>[],
    this.hasReachedMax = false,
    this.newsType = NewsType.top,
    this.feedMode = FeedMode.all,
    this.rssFeedFilter,
  });

  NewsState copyWith({
    NewsStatus? status,
    List<TitledItem>? news,
    bool? hasReachedMax,
    NewsType? newsType,
    FeedMode? feedMode,
    RssFeedInfo? rssFeedFilter,
  }) {
    return NewsState(
      status: status ?? this.status,
      news: news ?? this.news,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      newsType: newsType ?? this.newsType,
      feedMode: feedMode ?? this.feedMode,
      rssFeedFilter: rssFeedFilter ?? this.rssFeedFilter,
    );
  }

  @override
  List<Object?> get props =>
      [status, news, hasReachedMax, newsType, feedMode, rssFeedFilter];
}
