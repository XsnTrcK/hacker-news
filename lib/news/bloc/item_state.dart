import 'package:equatable/equatable.dart';
import 'package:hackernews/models/item.dart';

class ItemBlocState<T extends Item> {
  final T? item;
  const ItemBlocState({this.item});
}
