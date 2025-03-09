
import 'package:echo_share/configs/app_colors.dart';
import 'package:echo_share/configs/app_routes.dart';
import 'package:echo_share/models/swipe_event.dart';
import 'package:echo_share/models/tap_event.dart';
import 'package:echo_share/services/method_channel_services.dart';
import 'package:echo_share/services/network_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class RecordPage extends StatefulWidget {
  String token;

  RecordPage({super.key, required this.token});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final startingText = "Press start 👇 to begin recording";
  final stopingText = "Press stop 👇 to end recording";
  final ValueNotifier<bool> _recordingState = ValueNotifier<bool>(false);
  bool _isPoppingProgrammatically = false;

  @override
  initState() {
    super.initState();
    NetworkServices.instance.connect(widget.token);
    NetworkServices.instance.listen(onMessageRecieved);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      NetworkServices.instance
          .sendMessage("ScreenSize:${size.width}:${size.height}");
    });
  }

  startRecording() async {
    MethodChannelServices.screenRecordChannel
        .configImageRecieved(onImageRecieved);
    MethodChannelServices.controlChannel
        .configControlRecieved(onControlRecieved);
    final size = MediaQuery.of(context).size;
    final result =
        await MethodChannelServices.screenRecordChannel.startRecording(size);
    if (result == "Started Recording") {
      _recordingState.value = true;
    }
  }

  stopRecording() {
    _recordingState.value = false;
    MethodChannelServices.screenRecordChannel.stopRecording();
  }

  onImageRecieved(Uint8List image) {
    NetworkServices.instance.sendImage(image);
  }

  onMessageRecieved(dynamic message) {
    if (message is String) {
      if (message.contains('tap')) {
        MethodChannelServices.controlChannel
            .tap(TapEvent.fromJsonString(message));
      } else if (message.contains('swipe')) {
        MethodChannelServices.controlChannel
            .swipe(SwipeEvent.fromJsonString(message));
      } else if (message == "EXIT") {
        stopRecording();
        closeSession();
      }
    }
  }

  onControlRecieved(MethodCall call) {
    _recordingState.value = false;
  }

  closeSession() {
     _isPoppingProgrammatically = true;
    Navigator.popUntil(
        context, (route) => route.settings.name == AppRoutes.welcome);
  }

  @override
  void dispose() {
    stopRecording();
    NetworkServices.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
         if (!_isPoppingProgrammatically) {
          MethodChannelServices.controlChannel.moveToBackground();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 350),
                width: double.infinity,
                child: ValueListenableBuilder(
                    valueListenable: _recordingState,
                    builder: (context, state, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/logo.png"),
                          Text(
                            state ? stopingText : startingText,
                            style: theme.textTheme.titleLarge,
                          ),
                          TextButton(
                              onPressed: () {
                                state ? stopRecording() : startRecording();
                              },
                              style: theme.textButtonTheme.style!.copyWith(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    state ? AppColors.error : AppColors.primary),
                              ),
                              child: Text(
                                state ? "Stop" : "Start",
                              ))
                        ],
                      );
                    }),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: SafeArea(
                child: FloatingActionButton(
                  onPressed: () {
                    NetworkServices.instance.sendMessage("EXIT");
                    closeSession();
                  },
                  elevation: 0,
                  shape: const CircleBorder(),
                  backgroundColor: AppColors.primary,
                  mini: true,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
