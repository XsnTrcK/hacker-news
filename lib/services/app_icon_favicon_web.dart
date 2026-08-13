import 'package:web/web.dart' as web;

Future<void> updateFavicon(String href) async {
  final link =
      web.document.querySelector('link[rel="icon"]') as web.HTMLLinkElement?;
  link?.href = href;
}
