import 'package:hackernews/models/item.dart';

abstract class ItemEvent<T extends Item> {
  final T item;
  const ItemEvent(this.item);
}

class SaveToReadLaterEvent<T extends Item> extends ItemEvent<T> {
  const SaveToReadLaterEvent(T item) : super(item);
}

class HasBeenReadEvent<T extends Item> extends ItemEvent<T> {
  const HasBeenReadEvent(T item) : super(item);
}

class DisplayReaderModeEvent<T extends Item> extends ItemEvent<T> {
  const DisplayReaderModeEvent(T item) : super(item);
}
