// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hackernews/comments/views/comments_section.dart';
import 'package:hackernews/components/custom_text.dart';
import 'package:hackernews/components/item_details.dart';
import 'package:hackernews/components/swipe_up_sheet.dart';
import 'package:hackernews/components/web_view/web_view.dart';
import 'package:hackernews/models/item.dart';

class DisplayArticle extends StatelessWidget {
  final TitledItem item;
  const DisplayArticle(this.item, {Key? key}) : super(key: key);

  Widget _createDisplayDetails() {
    if (item is StoryItem) {
      return WebView((item as StoryItem).url);
    } else {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Html(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                data: item.text ?? item.title,
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQuery.of(context);
    var maxHeight = mediaQueryData.size.height -
        mediaQueryData.padding.top -
        mediaQueryData.padding.bottom;
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _createDisplayDetails()),
          SwipeUpSheet(
            maxHeight: maxHeight,
            headerMinimal: CustomText(
              item.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            headerBuilder: () => ItemDetails(item, expand: false),
            bodyBuilder: item is ItemWithKids
                ? () => CommentsSection((item as ItemWithKids))
                : null,
          ),
        ],
      ),
    );
  }
}
