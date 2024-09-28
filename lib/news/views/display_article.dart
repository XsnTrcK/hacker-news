// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hackernews/comments/views/comments_section.dart';
import 'package:hackernews/components/item_details.dart';
import 'package:hackernews/components/web_view/web_view.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/bloc/item_bloc.dart';
import 'package:hackernews/news/bloc/item_events.dart';
import 'package:hackernews/news/bloc/item_state.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DisplayArticle extends StatefulWidget {
  static final PanelController _panelController = PanelController();

  const DisplayArticle({Key? key}) : super(key: key);

  @override
  State<DisplayArticle> createState() => _DisplayArticle();
}

class _DisplayArticle extends State<DisplayArticle> {
  final GlobalKey<State<DisplayArticle>> _collapsedKey = GlobalKey();
  Size _collapsedSize = const Size(0, 0);

  Widget _createButtonsRow(
      TitledItem item, BuildContext context, bool collapsed) {
    return Row(
      children: [
        Expanded(
            child: IconButton(
          icon: Icon(item.state.displayReaderMode
              ? FluentIcons.reading_mode_solid
              : FluentIcons.reading_mode),
          onPressed: () {
            context
                .read<ItemBloc<TitledItem>>()
                .add(DisplayReaderModeEvent(item));
          },
        )),
        Expanded(
          flex: 8,
          child: item is ItemWithKids && item is StoryItem
              ? IconButton(
                  icon: Icon(collapsed
                      ? FluentIcons.chevron_up_small
                      : FluentIcons.chevron_down_small),
                  onPressed: () => collapsed
                      ? DisplayArticle._panelController.open()
                      : DisplayArticle._panelController.close(),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: IconButton(
            icon: Icon(item.state.savedForReadLater
                ? FluentIcons.single_bookmark_solid
                : FluentIcons.single_bookmark),
            onPressed: () {
              context
                  .read<ItemBloc<TitledItem>>()
                  .add(SaveToReadLaterEvent(item));
            },
          ),
        )
      ],
    );
  }

  Widget? _createInfo(TitledItem item) {
    var textHtml = item.text != null
        ? SingleChildScrollView(
            child: Html(
              data: '<body>${item.text}</body>',
              style: {
                "body": Style(
                  padding: HtmlPaddings.zero,
                  margin: Margins.symmetric(horizontal: 5),
                )
              },
            ),
          )
        : null;
    if (item is ItemWithKids) {
      return Expanded(
        child: CommentsSection(
          item,
          startWidget: textHtml,
        ),
      );
    }
    return textHtml;
  }

  Widget _createInfoSection(
      TitledItem item, BuildContext context, bool collapsed) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: ItemDetails(item, minimalTitle: collapsed, expand: false),
        ),
        !collapsed
            ? _createInfo(item) ?? const SizedBox.shrink()
            : const SizedBox.shrink(),
        _createButtonsRow(item, context, collapsed),
      ],
    );
  }

  void _postFrameCallback(_) {
    var context = _collapsedKey.currentContext;
    if (context == null) return;

    var newSize = context.size;
    if (_collapsedSize == newSize) return;

    setState(() {
      _collapsedSize = newSize!;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = FluentTheme.of(context);
    var mediaQueryData = MediaQuery.of(context);
    var maxHeight = mediaQueryData.size.height -
        mediaQueryData.padding.top -
        mediaQueryData.padding.bottom;
    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0),
      content: ColorfulSafeArea(
        color: theme.scaffoldBackgroundColor,
        child: BlocBuilder<ItemBloc<TitledItem>, ItemBlocState<TitledItem>>(
          builder: (context, state) {
            if (state.item != null) {
              if (state.item is StoryItem) {
                SchedulerBinding.instance
                    .addPostFrameCallback(_postFrameCallback);
                var storyItem = state.item as StoryItem;
                return SlidingUpPanel(
                  controller: DisplayArticle._panelController,
                  onPanelOpened: () {
                    if (!DisplayArticle._panelController.isPanelOpen) {
                      DisplayArticle._panelController.open();
                    }
                  },
                  onPanelClosed: () {
                    if (!DisplayArticle._panelController.isPanelClosed) {
                      DisplayArticle._panelController.close();
                    }
                  },
                  maxHeight: maxHeight,
                  minHeight: 76,
                  body: Padding(
                    padding: EdgeInsets.only(
                        bottom: _collapsedSize.height +
                            mediaQueryData.padding.top +
                            mediaQueryData.padding.bottom),
                    child: WebView(
                        storyItem.url, storyItem.state.displayReaderMode),
                  ),
                  collapsed: Container(
                    key: _collapsedKey,
                    color: theme.scaffoldBackgroundColor,
                    child: _createInfoSection(storyItem, context, true),
                  ),
                  panel: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: _createInfoSection(storyItem, context, false),
                  ),
                );
              }
              return SizedBox(
                height: maxHeight,
                child: _createInfoSection(state.item!, context, false),
              );
            } else {
              return const Center(child: ProgressBar());
            }
          },
        ),
      ),
    );
  }
}
