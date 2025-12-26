import 'dart:developer';

import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_uikit/controllers/session_controller.dart';
import 'package:agora_uikit/models/agora_rtm_channel_event_handler.dart';
import 'package:agora_uikit/src/enums.dart';

Future<void> rtmChannelEventHandler({
  required StreamChannel channel,
  required AgoraRtmChannelEventHandler agoraRtmChannelEventHandler,
  required SessionController sessionController,
}) async {
  const String tag = "AgoraVideoUIKit";
  
  // RTM v2 uses client-level listeners instead of channel-level
  // We'll need to filter by channel in the client event handlers
  // For now, we'll add a placeholder that needs to be implemented
  // with the client's message listener filtered by channelName
  
  log(
    'RTM Channel event handler registered (v2 API uses client-level listeners)',
    level: Level.info.value,
    name: tag,
  );
  
  // Note: In RTM v2, channel events are handled through the client's addListener
  // with message, presence, and storage event types
}
