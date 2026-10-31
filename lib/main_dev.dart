import 'package:property_manager/bootstrap.dart';
import 'package:property_manager/core/config/app_config.dart';
import 'package:property_manager/core/config/flavor.dart';

Future<void> main() =>
    bootstrap(AppConfig.fromEnvironment(flavor: Flavor.dev, appName: 'PM Dev'));
