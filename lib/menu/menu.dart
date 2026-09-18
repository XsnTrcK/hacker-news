import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:hackernews/components/labeled_icon_button.dart';
import 'package:hackernews/menu/menu_destinations.dart';
import 'package:hackernews/services/theme_extensions.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  void Function() _handleClick(
      BuildContext context, Widget Function() builder) {
    final theme = FluentTheme.of(context);
    return () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ColorfulSafeArea(
              color: theme.scaffoldBackgroundColor,
              child: builder(),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).dynamicTypography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
          child: Text(
            "Hacker Newser",
            textAlign: TextAlign.start,
            style: typography.display,
          ),
        ),
        for (final destination in menuDestinations) ...[
          LabeledIconButton(
            onPressed: _handleClick(context, destination.builder),
            icon: destination.icon,
            label: destination.label,
          ),
          const Divider(),
        ],
      ],
    );
  }
}
