import 'package:flutter/cupertino.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/views/display_article.dart';
import 'package:url_launcher/url_launcher.dart';

Future<TitledItem?> _getItemOrOpenUrl(String? url) async {
  if (url == null) return null;

  var uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains("ycombinator") && uri.path.contains("item")) {
    var itemId = int.tryParse(uri.queryParameters["id"] ?? "");
    if (itemId != null) {
      var item = await newsApiRetriever.getNewsItem(itemId);
      // TODO: Handle commeent items by getting parent until it is a TitledItem
      if (item is TitledItem) {
        return item;
      }
    }
  }

  await launchUrl(uri, mode: LaunchMode.platformDefault);
  return null;
}

void handleLinkTap(BuildContext context, String? url) async {
  var item = await _getItemOrOpenUrl(url);
  if (item == null) return;

  if (!context.mounted) return;
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => DisplayArticle(item),
    ),
  );
}
