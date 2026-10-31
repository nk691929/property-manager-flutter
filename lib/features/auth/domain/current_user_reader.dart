import 'package:property_manager/features/auth/domain/entities/app_user.dart';

/// Lets use cases ask "who is acting?" without depending on Riverpod.
typedef CurrentUserReader = AppUser? Function();
