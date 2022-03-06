// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:mdi/mdi.dart';

class LinkThumbnail extends StatelessWidget {
  final String url;
  final bool useFavicon;
  final EdgeInsetsGeometry padding;
  final bool returnFlexible;
  final bool showErrorIcon;

  const LinkThumbnail({
    Key? key,
    required this.url,
    this.useFavicon = false,
    this.padding = const EdgeInsets.all(0),
    this.returnFlexible = false,
    this.showErrorIcon = false,
  }) : super(key: key);

  String? _getImageUrl(InfoBase? info) {
    switch (info.runtimeType) {
      case WebVideoInfo:
        return (info as WebVideoInfo).image;
      case WebImageInfo:
        return (info as WebImageInfo).image;
      case WebInfo:
        final webInfo = (info as WebInfo);
        final favicon = webInfo.icon;
        if (useFavicon) {
          return favicon;
        }
        return webInfo.image;
      default:
        return null;
    }
  }

  IconData _getReplacementIcon(String url) {
    var firstChar = url.toLowerCase()[0];
    switch (firstChar) {
      case 'a':
        return Mdi.alphaA;
      case 'b':
        return Mdi.alphaB;
      case 'c':
        return Mdi.alphaC;
      case 'd':
        return Mdi.alphaD;
      case 'e':
        return Mdi.alphaE;
      case 'f':
        return Mdi.alphaF;
      case 'g':
        return Mdi.alphaG;
      case 'h':
        return Mdi.alphaH;
      case 'i':
        return Mdi.alphaI;
      case 'j':
        return Mdi.alphaJ;
      case 'k':
        return Mdi.alphaK;
      case 'l':
        return Mdi.alphaL;
      case 'm':
        return Mdi.alphaM;
      case 'n':
        return Mdi.alphaN;
      case 'o':
        return Mdi.alphaO;
      case 'p':
        return Mdi.alphaP;
      case 'q':
        return Mdi.alphaQ;
      case 'r':
        return Mdi.alphaR;
      case 's':
        return Mdi.alphaS;
      case 't':
        return Mdi.alphaT;
      case 'u':
        return Mdi.alphaU;
      case 'v':
        return Mdi.alphaV;
      case 'w':
        return Mdi.alphaW;
      case 'x':
        return Mdi.alphaX;
      case 'y':
        return Mdi.alphaY;
      case 'z':
        return Mdi.alphaZ;
      default:
        return FluentIcons.photo2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLinkPreview(
      key: key,
      url: url,
      builder: (InfoBase? info) {
        final imageUrl = _getImageUrl(info);
        if (imageUrl == null) {
          return const SizedBox.shrink();
        }
        final returnWidget = CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder: (context, imageProvider) {
            return Padding(
              padding: padding,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
          errorWidget: (_, __, ___) {
            return showErrorIcon
                ? Icon(
                    _getReplacementIcon(Uri.parse(imageUrl).host),
                    size: 100,
                  )
                : const SizedBox.shrink();
          },
        );
        return returnFlexible ? Expanded(child: returnWidget) : returnWidget;
      },
    );
  }
}
