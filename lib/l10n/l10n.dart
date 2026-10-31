import 'package:flutter/widgets.dart';
import 'package:property_manager/l10n/app_localizations.dart';

export 'package:property_manager/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
