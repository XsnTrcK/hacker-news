import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

class ThrottledBloc<TEvent, TState> extends Bloc<TEvent, TState> {
  static const Duration _throttleDuration = Duration(milliseconds: 100);

  ThrottledBloc(super.state);

  EventTransformer<E> throttleDroppable<E>() {
    return (events, mapper) =>
        droppable<E>().call(events.throttle(_throttleDuration), mapper);
  }
}
