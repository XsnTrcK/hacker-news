import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';

class SwipeUpSheet extends StatefulWidget {
  final Widget header;
  final Widget headerMinimal;
  final Widget? body;
  final double? maxHeight;

  const SwipeUpSheet({
    Key? key,
    required this.header,
    required this.headerMinimal,
    required this.body,
    required this.maxHeight,
  }) : super(key: key);

  @override
  _SwipeUpSheetState createState() => _SwipeUpSheetState();
}

class _SwipeUpSheetState extends State<SwipeUpSheet> {
  static const double _minHeight = 62;
  bool _isOpen = false;
  Offset _offset = const Offset(0, _SwipeUpSheetState._minHeight);

  // first it opens the sheet and when called again it closes.
  void _handleClick(double maxHeight) {
    _isOpen = !_isOpen;
    Timer.periodic(const Duration(milliseconds: 1), (timer) {
      if (_isOpen) {
        double value = _offset.dy +
            20; // we increment the height of the Container by 10 every 5ms
        _offset = Offset(0, value);
        if (_offset.dy > maxHeight) {
          _offset =
              Offset(0, maxHeight); // makes sure it does't go above maxHeight
          timer.cancel();
        }
      } else {
        double value = _offset.dy - 20; // we decrement the height by 10 here
        _offset = Offset(0, value);
        if (_offset.dy < _minHeight) {
          _offset = const Offset(
              0, _minHeight); // makes sure it doesn't go beyond minHeight
          timer.cancel();
        }
      }
      setState(() {});
    });
  }

  Widget _createContent(double maxWidth, double maxHeight) {
    var headerWidget = Padding(
      padding: const EdgeInsets.all(10),
      child: _isOpen ? widget.header : widget.headerMinimal,
    );
    return Column(
      children: [
        headerWidget,
        widget.body != null && _isOpen
            ? Expanded(
                child: widget.body!,
              )
            : const SizedBox.shrink(),
        widget.body != null
            ? ConstrainedBox(
                constraints: BoxConstraints(minWidth: maxWidth),
                child: IconButton(
                  icon: Icon(_isOpen
                      ? FluentIcons.chevron_down_small
                      : FluentIcons.chevron_up_small),
                  onPressed: () => _handleClick(maxHeight),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQuery.of(context);
    var maxHeight = widget.maxHeight ??
        (mediaQueryData.size.height -
            mediaQueryData.padding.top -
            mediaQueryData.padding.bottom);
    return AnimatedContainer(
      duration: Duration.zero,
      curve: Curves.easeOut,
      height: _offset.dy,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 10)
        ],
      ),
      child: _createContent(mediaQueryData.size.width, maxHeight),
    );
  }
}
