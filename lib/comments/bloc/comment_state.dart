import 'package:equatable/equatable.dart';
import 'package:hackernews/models/item.dart';

enum CommentStatus { initial, success, failure }

class CommentState {
  final CommentStatus status;
  final CommentItem? comment;

  const CommentState({
    this.status = CommentStatus.initial,
    this.comment,
  });
}
