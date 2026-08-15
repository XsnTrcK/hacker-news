import 'dart:convert';

import 'package:hackernews/rss/models/rss_story_item.dart';

extension ItemMap on Map<String, dynamic> {
  int get id => this["id"];
  int get time => this["time"];
  String get createdBy => this["by"] ?? "";
  String get title => this["title"];
  int get score => this["score"];
  List<int> get childrenIds => this["kids"]?.cast<int>() ?? [];
  int get numberOfChildren => this["descendants"];
  String get url => this["url"] ?? '';
  String get text => this["text"] ?? '';
  List<int> get pollOptionIds => this["parts"]?.cast<int>() ?? [];
  int get parentId => this["parent"];
  int get relatedPollId => this["poll"];
  bool get isDeleted => this["deleted"] ?? false;
  bool get isDead => this["dead"] ?? false;
  ItemState get state => ItemState.fromJson(this["state"]);
  bool get isExpanded => this["isExpanded"] ?? false;
  bool? get savedForReadLater => this["savedForReadLater"] as bool?;
  bool? get displayReaderMode => this["displayReaderMode"] as bool?;
  String get feedName => this["feedName"] ?? '';
  int? get hnItemId => this["hnItemId"];
}

class ItemState {
  bool isExpanded;
  bool? savedForReadLater;
  bool? displayReaderMode;

  ItemState({
    this.isExpanded = true,
    this.savedForReadLater,
    this.displayReaderMode,
  });

  factory ItemState.fromJson(Map<String, dynamic>? stateMap) {
    if (stateMap == null) return ItemState();
    return ItemState(
      isExpanded: stateMap.isExpanded,
      savedForReadLater: stateMap.savedForReadLater,
      displayReaderMode: stateMap.displayReaderMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isExpanded": isExpanded,
      "savedForReadLater": savedForReadLater,
      "displayReaderMode": displayReaderMode,
    };
  }
}

/// Lean persisted record for an article whose reader-mode or bookmark state
/// has been touched: `{id, displayReaderMode, bookmarked}`. Unlike
/// [Item.toMap]/[Item.fromJson], this shape carries no title/url/score/text/
/// kids/descendants and cannot reconstruct a full [Item].
class LeanItemRecord {
  final int id;
  final bool? displayReaderMode;
  final bool? bookmarked;

  const LeanItemRecord({
    required this.id,
    this.displayReaderMode,
    this.bookmarked,
  });

  String toJson() => jsonEncode({
        "id": id,
        "displayReaderMode": displayReaderMode,
        "bookmarked": bookmarked,
      });

  factory LeanItemRecord.fromJson(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return LeanItemRecord(
      id: jsonMap["id"] as int,
      displayReaderMode: jsonMap["displayReaderMode"] as bool?,
      bookmarked: jsonMap["bookmarked"] as bool?,
    );
  }
}

abstract class Item {
  int id;
  int time;
  String createdBy;
  String? text;
  ItemState state;

  Item(this.id, this.time, this.createdBy, this.state, {this.text});

  factory Item.fromJson(String jsonString) =>
      Item.fromMap(jsonDecode(jsonString));

  factory Item.fromMap(Map<String, dynamic> jsonMap) {
    switch (jsonMap["type"]) {
      case "rss":
        return RssStoryItem(
          id: jsonMap.id,
          time: jsonMap.time,
          createdBy: jsonMap.createdBy,
          state: jsonMap.state,
          title: jsonMap.title,
          url: jsonMap.url,
          feedName: jsonMap.feedName,
          hnItemId: jsonMap.hnItemId,
        );
      case "story":
        if (jsonMap.containsKey("url")) {
          return StoryItem(
              jsonMap.id,
              jsonMap.time,
              jsonMap.createdBy,
              jsonMap.state,
              jsonMap.title,
              jsonMap.score,
              jsonMap.childrenIds,
              jsonMap.numberOfChildren,
              jsonMap.url,
              text: jsonMap.text);
        } else {
          return AskItem(
            jsonMap.id,
            jsonMap.time,
            jsonMap.createdBy,
            jsonMap.state,
            jsonMap.text,
            jsonMap.title,
            jsonMap.score,
            jsonMap.childrenIds,
            jsonMap.numberOfChildren,
          );
        }
      case "job":
        return JobItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
          jsonMap.state,
          jsonMap.title,
          jsonMap.score,
          jsonMap.url,
        );
      case "poll":
        return PollItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
          jsonMap.state,
          jsonMap.text,
          jsonMap.title,
          jsonMap.score,
          jsonMap.childrenIds,
          jsonMap.numberOfChildren,
          jsonMap.pollOptionIds,
        );
      case "comment":
        return CommentItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
          jsonMap.state,
          jsonMap.text,
          jsonMap.childrenIds,
          jsonMap.parentId,
          jsonMap.isDeleted,
          jsonMap.isDead,
        );
      case "pollopt":
        return PollOptionItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
          jsonMap.state,
          jsonMap.text,
          jsonMap.score,
          jsonMap.relatedPollId,
        );
      default:
        throw Exception("Invalid item type");
    }
  }

  Map<String, dynamic> toMap() {
    final jsonDict = {
      "id": id,
      "time": time,
      "by": createdBy,
      "state": state.toMap()
    };
    if (text != null) {
      jsonDict["text"] = text!;
    }

    return jsonDict;
  }

  Map<String, dynamic> toLeanMap() => {
        "id": id,
        "displayReaderMode": state.displayReaderMode,
        "bookmarked": state.savedForReadLater,
      };

  String prettySinceMessage() {
    final itemDate = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    final currentDateTime = DateTime.now();

    final timeDifference = currentDateTime.difference(itemDate);

    if (timeDifference.inDays > 0) {
      return "${timeDifference.inDays} Days ago";
    } else if (timeDifference.inHours > 0) {
      return "${timeDifference.inHours} Hours ago";
    } else if (timeDifference.inMinutes > 0) {
      return "${timeDifference.inMinutes} Minutes ago";
    } else {
      return "Recently Posted";
    }
  }
}

abstract class TitledItem extends Item {
  String title;
  int score;

  TitledItem(super.id, super.time, super.createdBy, super.state, this.title,
      this.score,
      {super.text});

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["title"] = title;
    jsonDict["score"] = score;

    return jsonDict;
  }
}

abstract class ItemWithKids extends TitledItem {
  List<int> childrenIds;
  int numberOfChildren;

  ItemWithKids(super.id, super.time, super.createdBy, super.state, super.title,
      super.score, this.childrenIds, this.numberOfChildren,
      {super.text});

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["kids"] = childrenIds;
    jsonDict["descendants"] = numberOfChildren;

    return jsonDict;
  }
}

class StoryItem extends ItemWithKids {
  String url;

  StoryItem(super.id, super.time, super.createdBy, super.state, super.title,
      super.score, super.childrenIds, super.numberOfChildren, this.url,
      {super.text});

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["url"] = url;
    jsonDict["type"] = "story";

    return jsonDict;
  }
}

class AskItem extends ItemWithKids {
  AskItem(super.id, super.time, super.createdBy, super.state, String? text,
      super.title, super.score, super.childrenIds, super.numberOfChildren)
      : super(text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["type"] = "story";

    return jsonDict;
  }
}

class PollItem extends ItemWithKids {
  List<int> pollOptionIds;

  PollItem(
      super.id,
      super.time,
      super.createdBy,
      super.state,
      String text,
      super.title,
      super.score,
      super.childrenIds,
      super.numberOfChildren,
      this.pollOptionIds)
      : super(text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["parts"] = pollOptionIds;
    jsonDict["type"] = "poll";

    return jsonDict;
  }
}

class JobItem extends TitledItem {
  String url;

  JobItem(super.id, super.time, super.createdBy, super.state, super.title,
      super.score, this.url);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["url"] = url;
    jsonDict["type"] = "job";

    return jsonDict;
  }
}

class PollOptionItem extends Item {
  int score;
  int relatedPollId;

  PollOptionItem(super.id, super.time, super.createdBy, super.state,
      String text, this.score, this.relatedPollId)
      : super(text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["score"] = score;
    jsonDict["poll"] = relatedPollId;
    jsonDict["type"] = "pollopt";

    return jsonDict;
  }
}

class CommentItem extends Item {
  List<int> childrenIds;
  int parentId;
  bool isDeleted;
  bool isDead;

  CommentItem(super.id, super.time, super.createdBy, super.state, String text,
      this.childrenIds, this.parentId, this.isDeleted, this.isDead)
      : super(text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["kids"] = childrenIds;
    jsonDict["parent"] = parentId;
    jsonDict["deleted"] = isDeleted;
    jsonDict["dead"] = isDead;
    jsonDict["type"] = "comment";

    return jsonDict;
  }
}
