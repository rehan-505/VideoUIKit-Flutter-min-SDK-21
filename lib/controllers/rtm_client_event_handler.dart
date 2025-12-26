import 'dart:convert';
import 'dart:developer';

import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_uikit/controllers/rtm_controller_helper.dart';
import 'package:agora_uikit/controllers/rtm_token_handler.dart';
import 'package:agora_uikit/controllers/session_controller.dart';
import 'package:agora_uikit/models/agora_rtm_client_event_handler.dart';
import 'package:agora_uikit/models/rtm_message.dart';
import 'package:agora_uikit/src/enums.dart';

Future<void> rtmClientEventHandler({
  required RtmClient agoraRtmClient,
  required AgoraRtmClientEventHandler agoraRtmClientEventHandler,
  required SessionController sessionController,
}) async {
  const String tag = "AgoraVideoUIKit";

  agoraRtmClient.addListener(
    message: (MessageEvent event) {
      agoraRtmClientEventHandler.onMessageReceived?.call(event);
      
      if (event.message != null && event.messageType == RtmMessageType.string) {
        final messageText = String.fromCharCodes(event.message!);
        Message msg = Message(text: messageText);
        String? messageType;

        try {
          final body = json.decode(messageText);
          messageType = body['messageType'];
        } catch (e) {
          messageType = 'UserData';
        }

        messageReceived(
          messageType: messageType!,
          message: msg.toJson(),
          sessionController: sessionController,
        );
      }
    },
    linkState: (LinkStateEvent event) {
      // RTM v2 LinkStateEvent has different fields than v1
      // event.currentState is RtmLinkState, not RtmConnectionState
      // event.reason is String, not RtmConnectionChangeReason
      
      log(
        'Connection state changed : ${event.currentState.toString()}, reason : ${event.reason.toString()}',
        level: Level.info.value,
        name: tag,
      );
      
      // In RTM v2, we check for disconnected state
      if (event.currentState == RtmLinkState.disconnected) {
        agoraRtmClient.logout();
      }
    },
    token: (TokenEvent event) {
      // Handle token expiration in RTM v2
      // Token events don't have channelName in the TokenEvent structure
      agoraRtmClientEventHandler.onTokenExpired?.call();
      
      getRtmToken(
        tokenUrl: sessionController.value.connectionData!.tokenUrl,
        sessionController: sessionController,
      );
      
      agoraRtmClientEventHandler.onTokenPrivilegeWillExpire?.call();
    },
    presence: (PresenceEvent event) {
      // Handle presence events (similar to onPeersOnlineStatusChanged in v1)
      agoraRtmClientEventHandler.onPeersOnlineStatusChanged?.call(event);
    },
  );
}
