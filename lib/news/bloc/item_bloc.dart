import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/bloc/base_bloc.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/bloc/item_events.dart';
import 'package:hackernews/news/bloc/item_state.dart';
import 'package:hackernews/store/store.dart';

class ItemBloc<T extends Item>
    extends ThrottledBloc<ItemEvent<T>, ItemBlocState<T>> {
  final ItemUpdater _itemUpdater;

  ItemBloc(this._itemUpdater) : super(const ItemBlocState()) {
    on<SaveToReadLaterEvent<T>>(_onSaveToReadLater,
        transformer: throttleDroppable());
    on<HasBeenReadEvent<T>>(_onHasBeenRead, transformer: throttleDroppable());
    on<DisplayReaderModeEvent<T>>(_onDisplayReaderMode,
        transformer: throttleDroppable());
  }

  void _onSaveToReadLater(
      SaveToReadLaterEvent<T> event, Emitter<ItemBlocState<T>> emit) {
    try {
      final updatedItem = _itemUpdater.saveToReadLater(event.item);
      emit(ItemBlocState<T>(item: updatedItem));
    } catch (error) {
      log("Error: $error");
    }
  }

  void _onHasBeenRead(
      HasBeenReadEvent<T> event, Emitter<ItemBlocState<T>> emit) {
    try {
      final updatedItem = _itemUpdater.markHasBeenRead(event.item);
      emit(ItemBlocState<T>(item: updatedItem));
    } catch (error) {
      log("Error: $error");
    }
  }

  void _onDisplayReaderMode(
      DisplayReaderModeEvent<T> event, Emitter<ItemBlocState<T>> emit) {
    try {
      final updatedItem = _itemUpdater.displayReaderMode(event.item);
      emit(ItemBlocState<T>(item: updatedItem));
    } catch (error) {
      log("Error: $error");
    }
  }
}
