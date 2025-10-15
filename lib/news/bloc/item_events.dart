import 'package:hackernews/models/item.dart';

abstract class ItemEvent<T extends Item> {
  final T item;
  const ItemEvent(this.item);
}

class SaveToReadLaterEvent<T extends Item> extends ItemEvent<T> {
  const SaveToReadLaterEvent(super.item);
}

class HasBeenReadEvent<T extends Item> extends ItemEvent<T> {
  const HasBeenReadEvent(super.item);
}

class DisplayReaderModeEvent<T extends Item> extends ItemEvent<T> {
  const DisplayReaderModeEvent(super.item);
}
