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
  String get text => this["text"];
  List<int> get pollOptionIds => this["parts"]?.cast<int>() ?? [];
  int get parentId => this["parent"];
  int get relatedPollId => this["poll"];
  bool get isDeleted => this["deleted"] ?? false;
  bool get isDead => this["dead"] ?? false;
  ItemState get state => this["state"] == null
      ? const ItemState()
      : ItemState(isExpanded: this["state"]["isExpanded"]);
}

class ItemState extends Equatable {
  final bool isExpanded;
  const ItemState({this.isExpanded = true});

  Map<String, dynamic> toMap() {
    return {"isExpanded": isExpanded};
  }

  @override
  List<Object?> get props => [isExpanded];
}

abstract class Item extends Equatable {
  final int id;
  final int time;
  final String createdBy;
  final String? text;
  final ItemState state;

  const Item(this.id, this.time, this.createdBy,
      {this.text, this.state = const ItemState()});

  factory Item.fromJson(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    switch (jsonMap["type"]) {
      case "story":
        if (jsonMap.containsKey("url")) {
          return StoryItem(
            jsonMap.id,
            jsonMap.time,
            jsonMap.createdBy,
            jsonMap.title,
            jsonMap.score,
            jsonMap.childrenIds,
            jsonMap.numberOfChildren,
            jsonMap.url,
          );
        } else if (jsonMap.containsKey("text")) {
          return AskItem(
            jsonMap.id,
            jsonMap.time,
            jsonMap.createdBy,
            jsonMap.text,
            jsonMap.title,
            jsonMap.score,
            jsonMap.childrenIds,
            jsonMap.numberOfChildren,
          );
        } else {
          throw Exception("Invalid Story received");
        }
      case "job":
        return JobItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
          jsonMap.title,
          jsonMap.score,
          jsonMap.url,
        );
      case "poll":
        return PollItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
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
          jsonMap.text,
          jsonMap.childrenIds,
          jsonMap.parentId,
          jsonMap.isDeleted,
          jsonMap.isDead,
          jsonMap.state,
        );
      case "pollopt":
        return PollOptionItem(
          jsonMap.id,
          jsonMap.time,
          jsonMap.createdBy,
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

  @override
  List<Object?> get props => [id, time, createdBy, text];
}

abstract class TitledItem extends Item {
  final String title;
  final int score;

  const TitledItem(int id, int time, String createdBy, this.title, this.score,
      {String? text})
      : super(id, time, createdBy, text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["title"] = title;
    jsonDict["score"] = score;

    return jsonDict;
  }

  @override
  List<Object?> get props => super.props..addAll([title, score]);
}

abstract class ItemWithKids extends TitledItem {
  final List<int> childrenIds;
  final int numberOfChildren;

  const ItemWithKids(int id, int time, String createdBy, String title,
      int score, this.childrenIds, this.numberOfChildren,
      {String? text})
      : super(id, time, createdBy, title, score, text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["kids"] = childrenIds;
    jsonDict["descendants"] = numberOfChildren;

    return jsonDict;
  }

  @override
  List<Object?> get props =>
      super.props..addAll([childrenIds, numberOfChildren]);
}

class StoryItem extends ItemWithKids {
  final String url;

  const StoryItem(int id, int time, String createdBy, String title, int score,
      List<int> childrenIds, int numberOfChildren, this.url)
      : super(id, time, createdBy, title, score, childrenIds, numberOfChildren);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["url"] = url;
    jsonDict["type"] = "story";

    return jsonDict;
  }

  @override
  List<Object?> get props => super.props..add(url);
}

class AskItem extends ItemWithKids {
  const AskItem(int id, int time, String createdBy, String? text, String title,
      int score, List<int> childrenIds, int numberOfChildren)
      : super(id, time, createdBy, title, score, childrenIds, numberOfChildren,
            text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["type"] = "story";

    return jsonDict;
  }
}

class PollItem extends ItemWithKids {
  final List<int> pollOptionIds;

  const PollItem(
      int id,
      int time,
      String createdBy,
      String text,
      String title,
      int score,
      List<int> childrenIds,
      int numberOfChildren,
      this.pollOptionIds)
      : super(id, time, createdBy, title, score, childrenIds, numberOfChildren,
            text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["parts"] = pollOptionIds;
    jsonDict["type"] = "poll";

    return jsonDict;
  }

  @override
  List<Object?> get props => super.props..add(pollOptionIds);
}

class JobItem extends TitledItem {
  final String url;

  const JobItem(
      int id, int time, String createdBy, String title, int score, this.url)
      : super(id, time, createdBy, title, score);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["url"] = url;
    jsonDict["type"] = "job";

    return jsonDict;
  }

  @override
  List<Object?> get props => super.props..add(url);
}

class PollOptionItem extends Item {
  final int score;
  final int relatedPollId;

  const PollOptionItem(int id, int time, String createdBy, String text,
      this.score, this.relatedPollId)
      : super(id, time, createdBy, text: text);

  @override
  Map<String, dynamic> toMap() {
    final jsonDict = super.toMap();
    jsonDict["score"] = score;
    jsonDict["poll"] = relatedPollId;
    jsonDict["type"] = "pollopt";

    return jsonDict;
  }

  @override
  List<Object?> get props => super.props..addAll([score, relatedPollId]);
}

class CommentItem extends Item {
  final List<int> childrenIds;
  final int parentId;
  final bool isDeleted;
  final bool isDead;

  const CommentItem(
      int id,
      int time,
      String createdBy,
      String text,
      this.childrenIds,
      this.parentId,
      this.isDeleted,
      this.isDead,
      ItemState state)
      : super(id, time, createdBy, text: text, state: state);

  CommentItem copyWith(ItemState state) {
    return CommentItem(id, time, createdBy, text!, childrenIds, parentId,
        isDeleted, isDead, state);
  }

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

  @override
  List<Object?> get props =>
      super.props..addAll([childrenIds, parentId, isDeleted, isDead]);
}
