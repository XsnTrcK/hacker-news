import 'package:hackernews/models/item.dart';

class RssStoryItem extends StoryItem {
  final String feedName;
  int? hnItemId;

  RssStoryItem({
    required int id,
    required int time,
    required String createdBy,
    required ItemState state,
    required String title,
    required String url,
    required this.feedName,
    this.hnItemId,
  }) : super(id, time, createdBy, state, title, 0, [], 0, url);

  /// Returns a stable, negative hash so RSS IDs never collide with positive HN IDs.
  static int stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['type'] = 'rss';
    map['feedName'] = feedName;
    if (hnItemId != null) map['hnItemId'] = hnItemId;
    return map;
  }
}
