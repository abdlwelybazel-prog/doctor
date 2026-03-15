import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  final String callID;
  final String doctorID;
  final String patientID;
  final bool isDoctor;
  final String userName;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.callID,
    required this.doctorID,
    required this.patientID,
    required this.isDoctor,
    required this.userName,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    final userID = isDoctor ? doctorID : patientID;

    /// إعداد نوع المكالمة
    final ZegoUIKitPrebuiltCallConfig config = isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    /// إعدادات إضافية
    if (isVideoCall) {
      config
        ..turnOnCameraWhenJoining = true
        ..turnOnMicrophoneWhenJoining = true
        ..useSpeakerWhenJoining = true;

      config.layout = ZegoLayout.pictureInPicture();
    } else {
      config
        ..turnOnMicrophoneWhenJoining = true
        ..useSpeakerWhenJoining = true;
    }

    return WillPopScope(
      onWillPop: () async {
        /// منع الخروج بزر الرجوع أثناء المكالمة
        return false;
      },
      child: ZegoUIKitPrebuiltCall(
        appID: 1893786539,
        appSign:
        '7cf95f462dec2227c9fcd59050b2859891128852ad1a5843f1295779b39706b5',
        userID: userID,
        userName: userName,
        callID: callID,
        config: config,
      ),
    );
  }
}