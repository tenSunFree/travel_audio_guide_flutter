import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppLogPage extends StatelessWidget {
  const AppLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: AppLogger.talker);
  }
}
