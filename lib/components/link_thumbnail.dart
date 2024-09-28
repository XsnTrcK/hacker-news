// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

  IconData _getReplacementIcon(String host) {
    var firstChar = host.toLowerCase().replaceAll('www.', '')[0];
    switch (firstChar) {
      case 'a':
        return MdiIcons.alphaA;
      case 'b':
        return MdiIcons.alphaB;
      case 'c':
        return MdiIcons.alphaC;
      case 'd':
        return MdiIcons.alphaD;
      case 'e':
        return MdiIcons.alphaE;
      case 'f':
        return MdiIcons.alphaF;
      case 'g':
        return MdiIcons.alphaG;
      case 'h':
        return MdiIcons.alphaH;
      case 'i':
        return MdiIcons.alphaI;
      case 'j':
        return MdiIcons.alphaJ;
      case 'k':
        return MdiIcons.alphaK;
      case 'l':
        return MdiIcons.alphaL;
      case 'm':
        return MdiIcons.alphaM;
      case 'n':
        return MdiIcons.alphaN;
      case 'o':
        return MdiIcons.alphaO;
      case 'p':
        return MdiIcons.alphaP;
      case 'q':
        return MdiIcons.alphaQ;
      case 'r':
        return MdiIcons.alphaR;
      case 's':
        return MdiIcons.alphaS;
      case 't':
        return MdiIcons.alphaT;
      case 'u':
        return MdiIcons.alphaU;
      case 'v':
        return MdiIcons.alphaV;
      case 'w':
        return MdiIcons.alphaW;
      case 'x':
        return MdiIcons.alphaX;
      case 'y':
        return MdiIcons.alphaY;
      case 'z':
        return MdiIcons.alphaZ;
      default:
        return FluentIcons.photo2;
    }
  }

  Widget _getIconWidget(String url) {
    return showErrorIcon
        ? Icon(
            _getReplacementIcon(Uri.parse(url).host),
            size: 100,
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return FutureBuilder(
      future: AnyLinkPreview.getMetadata(link: url),
      builder: (context, AsyncSnapshot<Metadata?> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data?.image == null) {
            return const SizedBox.shrink();
          }
          final returnWidget = CachedNetworkImage(
            imageUrl: snapshot.data!.image!,
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
              return _getIconWidget(url);
            },
          );
          return returnFlexible ? Expanded(child: returnWidget) : returnWidget;
        } else if (snapshot.hasError) {
          return _getIconWidget(url);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
