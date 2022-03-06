import 'package:fluent_ui/fluent_ui.dart';

class CustomText extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final TextStyle style;
  final TextOverflow? overflow;

  const CustomText(
    this.text, {
    Key? key,
    this.padding = const EdgeInsets.symmetric(horizontal: 5),
    this.alignment = Alignment.centerLeft,
    this.style = const TextStyle(
      fontSize: 10,
    ),
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          overflow: overflow,
          style: style,
        ),
      ),
    );
  }
}
