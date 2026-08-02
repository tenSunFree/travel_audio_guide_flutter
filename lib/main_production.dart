import 'package:flutter_travel_audio_guide/bootstrap.dart';
import 'package:flutter_travel_audio_guide/config/firebase/firebase_options_production.dart';

/// Production flavor entrypoint.
/// `flutter build apk --flavor production -t lib/main_production.dart`
Future<void> main() async {
  await bootstrap(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
