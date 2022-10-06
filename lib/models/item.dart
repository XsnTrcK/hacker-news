import 'dart:convert';
import 'package:equatable/equatable.dart';

extension ItemMap on Map<String, dynamic> {
  int get id => this["id"];
  int get time => this["time"];
  String get createdBy => this["by"];
  String get title => this["title"];
  int get score => this["score"];
  List<int> get childrenIds => this["kids"]?.cast<int>() ?? [];
  int get numberOfChildren => this["descendants"];
  String get url => this["url"];
  String get text => this["text"] ?? '';
  List<int> get pollOptionIds => this["parts"]?.cast<int>() ?? [];
  int get parentId => this["parent"];
  int get relatedPollId => this["poll"];
  bool get isDeleted => this["deleted"] ?? false;
  bool get isDead => this["dead"] ?? false;
  ItemState get state => ItemState.fromJson(this["state"]);
  bool get isExpanded => this["isExpanded"] ?? false;
  bool get savedForReadLater => this["savedForReadLater"] ?? false;
  bool get hasBeenRead => this["hasBeenRead"] ?? false;
  bool get displayReaderMode => this["displayReaderMode"] ?? true;
}

class ItemState {
  bool isExpanded;
  bool savedForReadLater;
  bool hasBeenRead;
  bool displayReaderMode;

  ItemState({
    this.isExpanded = true,
    this.savedForReadLater = false,
    this.hasBeenRead = false,
    this.displayReaderMode = false,
  });

  factory ItemState.fromJson(Map<String, dynamic>? stateMap) {
    if (stateMap == null) return ItemState();
    return ItemState(
      isExpanded: stateMap.isExpanded,
      savedForReadLater: stateMap.savedForReadLater,
      hasBeenRead: stateMap.hasBeenRead,
      displayReaderMode: stateMap.displayReaderMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isExpanded": isExpanded,
      "savedForReadLater": savedForReadLater,
      "hasBeenRead": hasBeenRead,
      "displayReaderMode": displayReaderMode,
    };
  }
}

abstract class Item {
  int id;
  int time;
  String createdBy;
  String? text;
  ItemState state;

  Item(this.id, this.time, this.createdBy, this.state, {this.text});

  factory Item.fromJson(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    switch (jsonMap["type"]) {
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

  TitledItem(int id, int time, String createdBy, ItemState state, this.title,
      this.score,
      {String? text})
      : super(id, time, createdBy, state, text: text);

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

  ItemWithKids(int id, int time, String createdBy, ItemState state,
      String title, int score, this.childrenIds, this.numberOfChildren,
      {String? text})
      : super(id, time, createdBy, state, title, score, text: text);

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

  StoryItem(int id, int time, String createdBy, ItemState state, String title,
      int score, List<int> childrenIds, int numberOfChildren, this.url,
      {String? text})
      : super(id, time, createdBy, state, title, score, childrenIds,
            numberOfChildren,
            text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["url"] = url;
    jsonDict["type"] = "story";

    return jsonDict;
  }
}

class AskItem extends ItemWithKids {
  AskItem(int id, int time, String createdBy, ItemState state, String? text,
      String title, int score, List<int> childrenIds, int numberOfChildren)
      : super(id, time, createdBy, state, title, score, childrenIds,
            numberOfChildren,
            text: text);

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
      int id,
      int time,
      String createdBy,
      ItemState state,
      String text,
      String title,
      int score,
      List<int> childrenIds,
      int numberOfChildren,
      this.pollOptionIds)
      : super(id, time, createdBy, state, title, score, childrenIds,
            numberOfChildren,
            text: text);

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

  JobItem(int id, int time, String createdBy, ItemState state, String title,
      int score, this.url)
      : super(id, time, createdBy, state, title, score);

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

  PollOptionItem(int id, int time, String createdBy, ItemState state,
      String text, this.score, this.relatedPollId)
      : super(id, time, createdBy, state, text: text);

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

  CommentItem(int id, int time, String createdBy, ItemState state, String text,
      this.childrenIds, this.parentId, this.isDeleted, this.isDead)
      : super(id, time, createdBy, state, text: text);

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
