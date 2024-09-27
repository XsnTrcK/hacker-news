// ignore_for_file: import_of_legacy_library_into_null_safe

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

  IconData _getReplacementIcon(String url) {
    var firstChar = url.toLowerCase().replaceAll('www.', '')[0];
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

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return showErrorIcon
        ? Icon(
            _getReplacementIcon(Uri.parse(url).host),
            size: 100,
          )
        : const SizedBox.shrink();
    // return FlutterLinkPreview(
    //   key: key ?? const Key(""),
    //   url: url,
    //   builder: (InfoBase? info) {
    //     final imageUrl = _getImageUrl(info);
    //     if (imageUrl == null) {
    //       return const SizedBox.shrink();
    //     }
    //     final returnWidget = CachedNetworkImage(
    //       imageUrl: imageUrl,
    //       imageBuilder: (context, imageProvider) {
    //         return Padding(
    //           padding: padding,
    //           child: AspectRatio(
    //             aspectRatio: 1,
    //             child: Image(
    //               image: imageProvider,
    //               fit: BoxFit.cover,
    //             ),
    //           ),
    //         );
    //       },
    //       errorWidget: (_, __, ___) {
    //         return showErrorIcon
    //             ? Icon(
    //                 _getReplacementIcon(
    //                     Uri.parse(imageUrl.isNotEmpty ? imageUrl : url).host),
    //                 size: 100,
    //               )
    //             : const SizedBox.shrink();
    //       },
    //     );
    //     return returnFlexible ? Expanded(child: returnWidget) : returnWidget;
    //   },
    // );
  }
}
