import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/cupertino.dart';
import 'package:hackernews/components/web_view/web_view.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/views/display_article.dart';

void _openWebView(BuildContext context, String url) {
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => ColorfulSafeArea(
        bottom: false,
        child: WebView(url, false, eager: false),
      ),
    ),
  );
}

void handleLinkTap(BuildContext context, String? url) async {
  if (url == null) return;

  var uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!uri.host.contains("ycombinator") || !uri.path.contains("item")) {
    return _openWebView(context, url);
  }

  var itemId = int.tryParse(uri.queryParameters["id"] ?? "");
  if (itemId == null) {
    return _openWebView(context, url);
  }

  var newsRetriever = await getNewsApiRetriever();
  var item = await newsRetriever.getNewsItem(itemId);
  if (item is! TitledItem) {
    return _openWebView(context, url);
  }

  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => DisplayArticle(item),
    ),
  );
}
