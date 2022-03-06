import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/comments/bloc/comment_events.dart';
import 'package:hackernews/comments/bloc/comment_state.dart';

class CommentBloc extends ThrottledBloc<CommentEvent, CommentState> {
  final CommentsApi _commentsApi;

  CommentBloc(this._commentsApi) : super(const CommentState()) {
    on<FetchComment>(_onFetchComment, transformer: throttleDroppable());
  }

  Future _onFetchComment(FetchComment event, Emitter<CommentState> emit) async {
    try {
      final commenItem = await _commentsApi.getComment(event.commentId);
      emit(CommentState(status: CommentStatus.success, comment: commenItem));
    } catch (error) {
      log("Error: $error");
      emit(const CommentState(status: CommentStatus.failure));
    }
  }
}
