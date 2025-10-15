import 'package:hackernews/news/bloc/news_state.dart';

abstract class NewsEvent {
  final NewsType newsType;
  const NewsEvent(this.newsType);
}

class FetchNews extends NewsEvent {
  const FetchNews(super.newsType);
}

class RefreshNews extends NewsEvent {
  const RefreshNews(super.newsType);
}
