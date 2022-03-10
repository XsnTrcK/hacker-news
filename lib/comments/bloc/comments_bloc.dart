import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/comments/apis/comments_api.dart';
import 'package:hackernews/comments/bloc/comments_events.dart';
import 'package:hackernews/comments/bloc/comments_state.dart';

class CommentsBloc extends ThrottledBloc<CommentsEvent, CommentsState> {
  final CommentsHandler _commentsApi;

  CommentsBloc(this._commentsApi) : super(const CommentsState()) {
    on<FetchComments>(_onFetchComments, transformer: throttleDroppable());
  }

  Future _onFetchComments(
      FetchComments event, Emitter<CommentsState> emit) async {
    try {
      final comments = await _commentsApi.fetchComments(event.itemWithKids);
      emit(CommentsState(status: CommentsStatus.success, comments: comments));
    } catch (error) {
      log("Error: $error");
      emit(const CommentsState(status: CommentsStatus.failure));
    }
  }
}
