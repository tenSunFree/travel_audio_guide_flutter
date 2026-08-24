import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Minimal user information extracted from a Supabase Session.
/// Full profile (display_name, avatar_url, ...) is fetched by the Profile feature
/// from the Go backend at `/api/v1/me` and is not included here.
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({required String id, required String? email}) =
      _AppUser;
}
