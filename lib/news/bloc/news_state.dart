import 'package:equatable/equatable.dart';
import 'package:hackernews/models/item.dart';

enum NewsStatus { initial, sucess, failure }

class NewsState extends Equatable {
  final NewsStatus status;
  final List<TitledItem> news;
  final bool hasReachedMax;

  const NewsState({
    this.status = NewsStatus.initial,
    this.news = const <TitledItem>[],
    this.hasReachedMax = false,
  });

  NewsState copyWith({
    NewsStatus? status,
    List<TitledItem>? news,
    bool? hasReachedMax,
  }) {
    return NewsState(
      status: status ?? this.status,
      news: news ?? this.news,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, news, hasReachedMax];
}
