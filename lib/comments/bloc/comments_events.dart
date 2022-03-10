import 'package:hackernews/models/item.dart';

abstract class CommentsEvent {
  const CommentsEvent();
}

class FetchComments extends CommentsEvent {
  final ItemWithKids itemWithKids;
  const FetchComments(this.itemWithKids);
}
