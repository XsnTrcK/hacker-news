import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/models/item.dart';

StoryItem _story(int id, {ItemState? state}) => StoryItem(
      id,
      0,
      'alice',
      state ?? ItemState(),
      'Story $id',
      10,
      const [],
      0,
      'https://example.com/$id',
    );

void main() {
  test('hasBeenRead no longer appears anywhere in ItemState serialized form',
      () {
    final state = ItemState(displayReaderMode: true, savedForReadLater: true);
    expect(state.toMap().containsKey('hasBeenRead'), isFalse);

    final item = _story(1, state: state);
    expect(jsonEncode(item.toMap()).contains('hasBeenRead'), isFalse);
  });

  test('savedForReadLater defaults to null (never touched)', () {
    expect(ItemState().savedForReadLater, isNull);
  });

  test('toLeanMap carries only id/displayReaderMode/bookmarked', () {
    final item = _story(
      2,
      state: ItemState(displayReaderMode: true, savedForReadLater: false),
    );
    expect(item.toLeanMap(), {
      "id": 2,
      "displayReaderMode": true,
      "bookmarked": false,
    });
  });

  test('LeanItemRecord round-trips through JSON', () {
    const record =
        LeanItemRecord(id: 3, displayReaderMode: null, bookmarked: true);
    final decoded = LeanItemRecord.fromJson(record.toJson());
    expect(decoded.id, 3);
    expect(decoded.displayReaderMode, isNull);
    expect(decoded.bookmarked, true);
  });
}
