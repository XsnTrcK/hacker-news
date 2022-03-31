import 'package:fluent_ui/fluent_ui.dart';

class HighlightContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;

  const HighlightContainer(
      {required this.child, required this.isSelected, Key? key})
      : super(key: key);

  Widget _createDivider(ThemeData theme) {
    return Row(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Expanded(
          flex: 2,
          child: Divider(
            style: DividerThemeData(
              horizontalMargin: const EdgeInsets.symmetric(horizontal: 0),
              decoration: BoxDecoration(color: theme.accentColor.darkest),
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      children: [
        child,
        if (isSelected) _createDivider(theme),
      ],
    );
  }
}
