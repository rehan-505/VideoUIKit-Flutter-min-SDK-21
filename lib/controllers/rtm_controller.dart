import 'dart:convert';
import 'dart:developer';

import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_uikit/controllers/rtm_channel_event_handler.dart';
import 'package:agora_uikit/controllers/session_controller.dart';
import 'package:agora_uikit/models/agora_rtm_channel_event_handler.dart';
import 'package:agora_uikit/models/agora_rtm_mute_request.dart';
import 'package:agora_uikit/models/rtm_message.dart';
import 'package:agora_uikit/src/enums.dart';

/// Function to join the RTM channel and send the user data to everyone inside that channel.
Future<void> rtmMethods(
    {required AgoraRtmChannelEventHandler agoraRtmChannelEventHandler,
    required SessionController sessionController}) async {
  await _loginToRtm(sessionController);
  await _joinRtmChannel(
    agoraRtmChannelEventHandler,
    sessionController,
  );
  await sendUserData(
    toChannel: true,
    username: sessionController.value.connectionData!.username!,
    sessionController: sessionController,
  );
}

Future<void> _loginToRtm(SessionController sessionController) async {
  if (!sessionController.value.isLoggedIn) {
    try {
      // RTM v2 uses login method with token
      final (status, _) = await sessionController.value.agoraRtmClient!.login(
        sessionController.value.connectionData!.tempRtmToken ??
            sessionController.value.generatedRtmToken ??
            '',
      );
      
      if (!status.error) {
        sessionController.value =
            sessionController.value.copyWith(isLoggedIn: true);
        log(
          'Username : ${sessionController.value.connectionData!.username} and rtmId : ${sessionController.value.generatedRtmId} logged in',
          level: Level.info.value,
        );
      } else {
        log(
          'Login failed: ${status.reason}',
          level: Level.error.value,
        );
      }
    } catch (e) {
      log(
        'Error occurred while trying to login. ${e.toString()}',
        level: Level.error.value,
      );
    }
  }
}

Future<StreamChannel?> _createChannel({
  required String rtmChannelName,
  required AgoraRtmChannelEventHandler agoraRtmChannelEventHandler,
  required SessionController sessionController,
}) async {
  // RTM v2 uses StreamChannel instead of RtmChannel
  final (status, channel) = await sessionController.value.agoraRtmClient!
      .createStreamChannel(rtmChannelName);

  if (!status.error && channel != null) {
    await rtmChannelEventHandler(
      channel: channel,
      agoraRtmChannelEventHandler: agoraRtmChannelEventHandler,
      sessionController: sessionController,
    );
  }
  return channel;
}

Future<void> _joinRtmChannel(
    AgoraRtmChannelEventHandler agoraRtmChannelEventHandler,
    SessionController sessionController) async {
  if (!sessionController.value.isInChannel) {
    try {
      final channel = await _createChannel(
        rtmChannelName:
            sessionController.value.connectionData?.rtmChannelName ??
                sessionController.value.connectionData!.channelName,
        agoraRtmChannelEventHandler: agoraRtmChannelEventHandler,
        sessionController: sessionController,
      );
      
      sessionController.value = sessionController.value.copyWith(
        agoraRtmChannel: channel,
      );
      
      // RTM v2 uses join method on StreamChannel
      if (channel != null) {
        final (status, _) = await channel.join();
        if (!status.error) {
          sessionController.value =
              sessionController.value.copyWith(isInChannel: true);
        } else {
          log('RTM Join channel error : ${status.reason}', level: Level.error.value);
        }
      }
    } catch (e) {
      log('RTM Join channel error : ${e.toString()}', level: Level.error.value);
    }
  }
}

Future<void> sendUserData({
  required bool toChannel,
  required String username,
  String? peerRtmId,
  required SessionController sessionController,
}) async {
  int ts = DateTime.now().millisecondsSinceEpoch;

  var userData = UserData(
    rtmId: sessionController.value.generatedRtmId!,
    rtcId: sessionController.value.localUid,
    username: username,
    role: sessionController.value.clientRoleType.index,
  );

  var json = jsonEncode(userData);

  Message message = Message(text: json, ts: ts, offline: false);

  if (sessionController.value.agoraRtmChannel != null && toChannel) {
    // RTM v2 uses publishTextMessage on StreamChannel
    // First we need to join a topic
    final channelName = await sessionController.value.agoraRtmChannel!.getChannelName();
    if (channelName.$2 != null) {
      // Publish to the default topic
      await sessionController.value.agoraRtmChannel!.publishTextMessage(
        'default',
        message.text,
      );
      log('User data sent to channel', level: Level.info.value);
    }
  } else if (sessionController.value.agoraRtmClient != null &&
      !toChannel &&
      peerRtmId != null) {
    // RTM v2 uses publish method with RtmChannelType.user for peer-to-peer
    await sessionController.value.agoraRtmClient!.publish(
      peerRtmId,
      message.text,
      channelType: RtmChannelType.user,
    );
    log('User data sent to peer', level: Level.info.value);
  } else {
    log("No user in the channel", level: Level.warning.value);
  }
}
