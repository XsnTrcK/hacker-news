import 'package:flutter/cupertino.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/apis/news_api.dart';
import 'package:hackernews/news/views/display_article.dart';
import 'package:hackernews/rss/apis/hn_search_api.dart';
import 'package:hackernews/store/store.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ItemFetcher = Future<Item?> Function(int itemId);
typedef UrlOpener = Future<void> Function(Uri uri);
typedef ArticleBuilder = Widget Function(TitledItem titledItem, Item? item);
typedef HnMatchFinder = Future<ItemWithKids?> Function(String url);

Future<Item?> _getNewsItem(int itemId) async {
  if (newsStore.containsKey(itemId)) {
    return newsStore.get(itemId);
  }
  final item = await newsApiRetriever.getNewsItem(itemId);
  newsStore.applyStoredState(item);
  newsStore.save(item);
  return item;
}

Future<void> _launchUrl(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

Future<ItemWithKids?> _defaultFindHnMatch(String url) {
  return HnSearchApi.findHnItemForUrl(url, httpClient);
}

bool _isHnItemLink(Uri uri) =>
    uri.host == "news.ycombinator.com" && uri.path.contains("item");

/// Normalizes a URL to lowercase host + trailing-slash-stripped path for
/// match comparison; query string and fragment are ignored.
String normalizeUrlForComparison(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  var path = uri.path;
  while (path.isNotEmpty && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return '${uri.host.toLowerCase()}$path';
}

/// True only when [candidate] is a story with a URL matching [tappedUrl]
/// after normalization. Ask/Poll items carry no URL and are always rejected.
bool isVerifiedMatch(String tappedUrl, ItemWithKids? candidate) {
  if (candidate is! StoryItem) return false;
  return normalizeUrlForComparison(candidate.url) ==
      normalizeUrlForComparison(tappedUrl);
}

/// Count of in-flight comment-link HN discussion lookups, incremented and
/// decremented by [LinkHandler.handleCommentLinkTap] itself. The comments
/// view listens to this to show a non-blocking "checking" indicator.
final ValueNotifier<int> pendingCommentLinkChecks = ValueNotifier(0);

class LinkHandler {
  LinkHandler(
      {ItemFetcher? fetchItem,
      UrlOpener? openUrl,
      ArticleBuilder? buildArticle,
      HnMatchFinder? findHnMatch,
      Duration? lookupTimeout})
      : _fetchItem = fetchItem ?? _getNewsItem,
        _openUrl = openUrl ?? _launchUrl,
        _buildArticle = buildArticle ??
            ((titledItem, item) => DisplayArticle(
                  titledItem,
                  childId: item?.id,
                )),
        _findHnMatch = findHnMatch ?? _defaultFindHnMatch,
        // Bounds a comment-link tap's worst case: fast enough that the
        // banner doesn't linger, generous enough for a real Algolia round trip.
        _lookupTimeout = lookupTimeout ?? const Duration(seconds: 5);

  final ItemFetcher _fetchItem;
  final UrlOpener _openUrl;
  final ArticleBuilder _buildArticle;
  final HnMatchFinder _findHnMatch;
  final Duration _lookupTimeout;

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
    if (_isHnItemLink(uri)) {
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

  Future<void> handleCommentLinkTap(BuildContext context, String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (_isHnItemLink(uri)) {
      await handleLinkTap(context, url);
      return;
    }

    pendingCommentLinkChecks.value++;
    try {
      ItemWithKids? match;
      try {
        match = await _findHnMatch(url).timeout(_lookupTimeout);
      } catch (_) {
        match = null;
      }

      if (isVerifiedMatch(url, match)) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => _buildArticle(match!, null),
          ),
        );
        return;
      }

      await _openUrl(uri);
    } finally {
      pendingCommentLinkChecks.value--;
    }
  }
}

final LinkHandler _defaultLinkHandler = LinkHandler();

void handleLinkTap(BuildContext context, String? url) async {
  await _defaultLinkHandler.handleLinkTap(context, url);
}

void handleCommentLinkTap(BuildContext context, String? url) async {
  await _defaultLinkHandler.handleCommentLinkTap(context, url);
}
