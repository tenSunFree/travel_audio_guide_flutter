import 'package:flutter_travel_audio_guide/bootstrap.dart';
import 'package:flutter_travel_audio_guide/config/firebase/firebase_options_staging.dart';

/// Staging flavor entrypoint.
/// `flutter build apk --flavor staging -t lib/main_staging.dart`
Future<void> main() async {
  await bootstrap(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
