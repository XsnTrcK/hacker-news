import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/services/theme_extensions.dart';

class LabeledIconButton extends StatelessWidget {
  final void Function() onPressed;
  final IconData? icon;
  final String? label;
  const LabeledIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).dynamicTypography;
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
              child: Icon(icon),
            ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
              child: Text(label!, style: typography.title),
            ),
        ],
      ),
    );
  }
}
