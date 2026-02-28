import 'package:flutter/cupertino.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/views/display_article.dart';
import 'package:hackernews/store/store.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ItemFetcher = Future<Item?> Function(int itemId);
typedef UrlOpener = Future<void> Function(Uri uri);
typedef ArticleBuilder = Widget Function(TitledItem titledItem, Item? item);

Future<Item?> _getNewsItem(int itemId) async {
  if (newsStore.containsKey(itemId)) {
    return newsStore.get(itemId);
  }
  final item = await newsApiRetriever.getNewsItem(itemId);
  newsStore.save(item);
  return item;
}

Future<void> _launchUrl(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

class LinkHandler {
  LinkHandler(
      {ItemFetcher? fetchItem,
      UrlOpener? openUrl,
      ArticleBuilder? buildArticle})
      : _fetchItem = fetchItem ?? _getNewsItem,
        _openUrl = openUrl ?? _launchUrl,
        _buildArticle = buildArticle ??
            ((titledItem, item) => DisplayArticle(
                  titledItem,
                  childId: item?.id,
                ));

  final ItemFetcher _fetchItem;
  final UrlOpener _openUrl;
  final ArticleBuilder _buildArticle;

  Future<TitledItem?> _resolveToTitledItem(Item item) async {
    if (item is TitledItem) return item;

    const maxDepth = 50;
    final visited = <int>{};
    Item current = item;
    var depth = 0;

    while (current is CommentItem && depth < maxDepth) {
      if (!visited.add(current.id)) return null;
      final parent = await _fetchItem(current.parentId);
      if (parent == null) return null;
      if (parent is TitledItem) return parent;
      current = parent;
      depth += 1;
    }

    return null;
  }

  Future<(TitledItem?, Item?)> getItemOrOpenUrl(String? url) async {
    if (url == null) return (null, null);

    var uri = Uri.tryParse(url);
    if (uri == null) return (null, null);
    if (uri.host.contains("ycombinator") && uri.path.contains("item")) {
      var itemId = int.tryParse(uri.queryParameters["id"] ?? "");
      if (itemId != null) {
        final item = await _fetchItem(itemId);
        if (item != null) {
          final titledItem = await _resolveToTitledItem(item);
          if (titledItem != null) {
            if (titledItem != item) return (titledItem, item);
            return (titledItem, null);
          }
        }
      }
    }

    await _openUrl(uri);
    return (null, null);
  }

  Future<void> handleLinkTap(BuildContext context, String? url) async {
    var (titledItem, item) = await getItemOrOpenUrl(url);
    if (titledItem == null) return;

    if (!context.mounted) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => _buildArticle(titledItem, item),
      ),
    );
  }
}

final LinkHandler _defaultLinkHandler = LinkHandler();

void handleLinkTap(BuildContext context, String? url) async {
  await _defaultLinkHandler.handleLinkTap(context, url);
}
