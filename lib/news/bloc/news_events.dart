import 'package:hackernews/news/bloc/news_state.dart';
import 'package:hackernews/rss/models/rss_feed.dart';

abstract class NewsEvent {
  final NewsType newsType;
  final FeedMode feedMode;
  final RssFeedInfo? rssFeedFilter;
  const NewsEvent(this.newsType,
      {this.feedMode = FeedMode.all, this.rssFeedFilter});
}

class FetchNews extends NewsEvent {
  const FetchNews(super.newsType, {super.feedMode, super.rssFeedFilter});
}

class RefreshNews extends NewsEvent {
  const RefreshNews(super.newsType, {super.feedMode, super.rssFeedFilter});
}
