// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
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

class DisplayArticle extends StatelessWidget {
  static final PanelController _panelController = PanelController();

  const DisplayArticle({Key? key}) : super(key: key);

  Widget _createDisplayDetails(TitledItem item) {
    if (item is StoryItem) {
      return WebView(item.url, item.state.displayReaderMode);
    } else {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Html(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                data: item.text ?? item.title,
              ),
            ),
          ),
        ],
      );
    }
  }

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
          child: item is ItemWithKids
              ? IconButton(
                  icon: Icon(collapsed
                      ? FluentIcons.chevron_up_small
                      : FluentIcons.chevron_down_small),
                  onPressed: () => collapsed
                      ? _panelController.open()
                      : _panelController.close(),
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

  Widget _createSlideView(
      TitledItem item, BuildContext context, bool collapsed) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: ItemDetails(item, minimalTitle: collapsed, expand: false),
        ),
        !collapsed
            ? item is ItemWithKids
                ? Expanded(child: CommentsSection(item))
                : const SizedBox.shrink()
            : const SizedBox.shrink(),
        _createButtonsRow(item, context, collapsed),
      ],
    );
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
              return SlidingUpPanel(
                controller: _panelController,
                onPanelOpened: () {
                  if (!_panelController.isPanelOpen) {
                    _panelController.open();
                  }
                },
                onPanelClosed: () {
                  if (!_panelController.isPanelClosed) {
                    _panelController.close();
                  }
                },
                maxHeight: maxHeight,
                minHeight: 76,
                body: _createDisplayDetails(state.item!),
                collapsed: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: _createSlideView(state.item!, context, true),
                ),
                panel: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: _createSlideView(state.item!, context, false),
                ),
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
