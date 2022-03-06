import 'package:fluent_ui/fluent_ui.dart';

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
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
