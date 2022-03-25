import 'package:fluent_ui/fluent_ui.dart';

class HighlightContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final double? width;

  const HighlightContainer(
      {required this.child, required this.isSelected, this.width, Key? key})
      : super(key: key);

  Widget _createDivider(ThemeData theme) {
    var divider = Divider(
      style: DividerThemeData(
        horizontalMargin: EdgeInsets.symmetric(
            horizontal: width == null ? 10 : width! * 0.15),
        decoration: BoxDecoration(color: theme.accentColor.darkest),
      ),
    );
    if (width != null) {
      return SizedBox.fromSize(
        size: Size(width!, 1),
        child: divider,
      );
    }
    return divider;
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
