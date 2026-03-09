import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/rss/bloc/rss_feeds_events.dart';
import 'package:hackernews/rss/bloc/rss_feeds_state.dart';
import 'package:hackernews/rss/store/rss_feeds_store.dart';

class RssFeedsBloc extends ThrottledBloc<RssFeedsEvent, RssFeedsState> {
  RssFeedsBloc()
      : super(RssFeedsState(List.of(rssFeedsStore.feeds))) {
    on<AddRssFeedEvent>(_onAdd, transformer: throttleDroppable());
    on<RemoveRssFeedEvent>(_onRemove, transformer: throttleDroppable());
  }

  void _onAdd(AddRssFeedEvent event, Emitter<RssFeedsState> emit) {
    rssFeedsStore.addFeed(event.feed);
    emit(RssFeedsState(List.of(rssFeedsStore.feeds)));
  }

  void _onRemove(RemoveRssFeedEvent event, Emitter<RssFeedsState> emit) {
    rssFeedsStore.removeFeed(event.index);
    emit(RssFeedsState(List.of(rssFeedsStore.feeds)));
  }
}
