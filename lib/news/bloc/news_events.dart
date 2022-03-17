import 'package:hackernews/news/bloc/news_state.dart';

abstract class NewsEvent {
  final NewsType newsType;
  const NewsEvent(this.newsType);
}

class FetchNews extends NewsEvent {
  const FetchNews(NewsType newsType) : super(newsType);
}

class RefreshNews extends NewsEvent {
  const RefreshNews(NewsType newsType) : super(newsType);
}
