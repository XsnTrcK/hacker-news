import 'package:fluent_ui/fluent_ui.dart';

class GestureDetectorWrapper extends StatelessWidget {
  final Widget child;
  final GestureDragUpdateCallback onPanUpdate;

  const GestureDetectorWrapper({
    Key? key,
    required this.child,
    required this.onPanUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: child,
    );
  }
}
