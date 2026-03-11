import 'package:hackernews/rss/models/rss_feed.dart';

abstract class RssFeedsEvent {
  const RssFeedsEvent();
}

class AddRssFeedEvent extends RssFeedsEvent {
  final RssFeedInfo feed;
  const AddRssFeedEvent(this.feed);
}

class RemoveRssFeedEvent extends RssFeedsEvent {
  final int index;
  const RemoveRssFeedEvent(this.index);
}
