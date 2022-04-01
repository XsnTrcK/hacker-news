// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hackernews/comments/views/comments_section.dart';
import 'package:hackernews/components/item_details.dart';
import 'package:hackernews/components/swipe_up_sheet.dart';
import 'package:hackernews/components/web_view/web_view.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/bloc/item_bloc.dart';
import 'package:hackernews/news/bloc/item_events.dart';
import 'package:hackernews/news/bloc/item_state.dart';

class DisplayArticle extends StatelessWidget {
  const DisplayArticle({Key? key}) : super(key: key);

  Widget _createDisplayDetails(TitledItem item) {
    if (item is StoryItem) {
      return WebView(item.url);
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
              return Column(
                children: [
                  Expanded(child: _createDisplayDetails(state.item!)),
                  SwipeUpSheet(
                    maxHeight: maxHeight,
                    headerBuilder: (minimal) => ItemDetails(state.item!,
                        minimalTitle: minimal, expand: false),
                    extraButtonBuilder: () => IconButton(
                      icon: Icon(state.item!.state.savedForReadLater
                          ? FluentIcons.single_bookmark_solid
                          : FluentIcons.single_bookmark),
                      onPressed: () {
                        context
                            .read<ItemBloc<TitledItem>>()
                            .add(SaveToReadLaterEvent(state.item!));
                      },
                    ),
                    bodyBuilder: state.item is ItemWithKids
                        ? () => CommentsSection((state.item as ItemWithKids))
                        : null,
                  ),
                ],
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
