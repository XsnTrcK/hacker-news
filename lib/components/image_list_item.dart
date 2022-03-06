import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/components/custom_text.dart';
import 'package:hackernews/components/item_details.dart';
import 'package:hackernews/components/link_thumbnail.dart';
import 'package:hackernews/models/item.dart';

class ImageListItem extends StatelessWidget {
  final TitledItem item;
  final double? maxHeight;

  const ImageListItem(this.item, {Key? key, this.maxHeight}) : super(key: key);

  Widget _createUrlInfo() {
    switch (item.runtimeType) {
      case StoryItem:
      case JobItem:
        final url = Uri.parse((item as dynamic).url);
        return Expanded(
          child: Row(
            children: [
              LinkThumbnail(
                url: url.toString(),
                useFavicon: true,
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              ),
              Expanded(
                child: CustomText(url.host),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _createDetails() {
    return Column(
      children: [
        _createUrlInfo(),
        Expanded(
          flex: 5,
          child: ItemDetails(item),
        ),
      ],
    );
  }

  Widget _createListView() {
    final details = _createDetails();
    switch (item.runtimeType) {
      case StoryItem:
      case JobItem:
        final String url = (item as dynamic).url;
        return Row(
          children: [
            Expanded(flex: 3, child: details),
            LinkThumbnail(
              url: url,
              returnFlexible: true,
              showErrorIcon: true,
            ),
          ],
        );
      default:
        return details;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight ?? 0),
      child: _createListView(),
    );
  }
}
