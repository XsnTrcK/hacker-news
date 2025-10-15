import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/services/theme_extensions.dart';

import 'custom_text.dart';

class ItemDetails extends StatelessWidget {
  final TitledItem item;
  final bool minimalTitle;
  final bool expand;
  final TextOverflow? overflow;

  const ItemDetails(
    this.item, {
    super.key,
    this.overflow,
    this.minimalTitle = false,
    this.expand = true,
  });

  String rightItemDetails(TitledItem item) {
    var itemDetails = "Score: ${item.score}";
    if (item is ItemWithKids) {
      itemDetails += "- ${item.numberOfChildren} comments";
    }
    return itemDetails;
  }

  Widget _expandIfNeeded(Widget widget, {int? flex}) {
    return expand
        ? Expanded(
            flex: flex ?? 1,
            child: widget,
          )
        : widget;
  }

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).dynamicTypography;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _expandIfNeeded(
          CustomText(
            item.title,
            overflow: overflow ?? (minimalTitle ? TextOverflow.ellipsis : null),
            style: minimalTitle
                ? typography.caption!.merge(
                    const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : typography.subtitle!.merge(
                    const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          flex: 4,
        ),
        _expandIfNeeded(
          Row(
            children: [
              Expanded(
                child: CustomText(
                    "${item.createdBy} - ${item.prettySinceMessage()}"),
              ),
              Expanded(
                child: CustomText(
                  rightItemDetails(item),
                  alignment: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
