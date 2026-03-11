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

  /// Returns a stable ID for an RSS item URL.
  ///
  /// Bit 31 is always set (the value is always >= 0x80000000 / ~2.1 billion),
  /// which reserves a high-bit range that real Hacker News item IDs (currently
  /// ~43 million and growing sequentially) will never reach. This guarantees
  /// RSS IDs and HN IDs never collide in the store.
  static int stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h | 0x80000000;
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
