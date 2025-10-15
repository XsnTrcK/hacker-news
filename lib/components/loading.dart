import 'package:fluent_ui/fluent_ui.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: ProgressRing(),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Text('Awaiting result...'),
          ),
        ),
      ],
    );
  }
}
