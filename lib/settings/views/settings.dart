import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:hackernews/settings/bloc/settings_bloc.dart';
import 'package:hackernews/settings/bloc/settings_events.dart';
import 'package:hackernews/store/settings_store.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final typography = theme.dynamicTypography;
    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
            child: Text(
              "Settings",
              textAlign: TextAlign.start,
              style: typography.display,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Row(
              children: [
                Text(
                  "Font Size:",
                  style: typography.bodyStrong,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: RadioButton(
                          content: const Text("Small"),
                          checked: settings.fontSize == SettingsFontSize.small,
                          onChanged: (checked) {
                            if (checked) {
                              context.read<SettingsBloc>().add(
                                  const UpdateFontSizeEvent(
                                      SettingsFontSize.small));
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: RadioButton(
                          content: const Text("Medium"),
                          checked: settings.fontSize == SettingsFontSize.medium,
                          onChanged: (checked) {
                            if (checked) {
                              context.read<SettingsBloc>().add(
                                  const UpdateFontSizeEvent(
                                      SettingsFontSize.medium));
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: RadioButton(
                          content: const Text("Large"),
                          checked: settings.fontSize == SettingsFontSize.large,
                          onChanged: (checked) {
                            if (checked) {
                              context.read<SettingsBloc>().add(
                                  const UpdateFontSizeEvent(
                                      SettingsFontSize.large));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
