import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/models/item.dart';

import 'custom_text.dart';

class ItemDetails extends StatelessWidget {
  final TitledItem item;
  final bool minimalTitle;
  final bool expand;

  const ItemDetails(this.item,
      {Key? key, this.minimalTitle = false, this.expand = true})
      : super(key: key);

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
            child: widget,
            flex: flex ?? 1,
          )
        : widget;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _expandIfNeeded(
          CustomText(
            item.title,
            overflow: minimalTitle ? TextOverflow.ellipsis : null,
            style: minimalTitle
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                : const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
