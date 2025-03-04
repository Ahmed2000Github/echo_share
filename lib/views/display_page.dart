import 'dart:math';

import 'package:echo_share/models/swipe_event.dart';
import 'package:echo_share/models/tap_event.dart';
import 'package:echo_share/views/widgets/icon_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DisplayPage extends StatefulWidget {
  const DisplayPage({Key? key}) : super(key: key);

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  static const recordChannel = MethodChannel('screen_record');
  static const controlChannel = MethodChannel('control_channel');
  WebSocketChannel? channel;
  late Stream<Uint8List?> imageStream;
  Offset _startPoint = Offset.zero;
  Offset _endPoint = Offset.zero;
  final _remoteSize = const Size(360, 800);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:5258/ws'));
    final broadcastStream = channel!.stream.asBroadcastStream();
    imageStream = broadcastStream.map((data) {
      if (data is Uint8List) return data;
      return null;
    });
  }

  double clampValue(double value) {
    return value > 0 ? value : 10;
  }

  double getScaleFactor(Size size) {
    return max(_remoteSize.width / (size.width - 10),
        _remoteSize.height / (size.height - 10));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleFactor = getScaleFactor(size);
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: Row(
              children: [
                SizedBox(
                  height: _remoteSize.height / scaleFactor,
                  width: _remoteSize.width / scaleFactor,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: GestureDetector(
                      onTapUp: (TapUpDetails details) {
                        final globalX = details.localPosition.dx;
                        final globalY = details.localPosition.dy;
                        final event =
                            TapEvent(actionName: "tap", x: globalX, y: globalY);
                        print("&&&&&&&&&&&&&&&&&&&& ${event.toJsonString()}");
                        event.x = details.localPosition.dx * 2 * scaleFactor;
                        event.y = details.localPosition.dy * 2 * scaleFactor;
                        print("@@@@@@@@@@@@@@@@@@@@@ ${event.toJsonString()}");
                        channel!.sink.add(event.toJsonString());
                      },
                      onPanStart: (DragStartDetails details) {
                        // Record the start point of the swipe
                        _startPoint = details.localPosition;
                      },
                      onPanUpdate: (DragUpdateDetails details) {
                        _endPoint = details.localPosition;
                      },
                      onPanEnd: (DragEndDetails details) {
                        final event = SwipeEvent(
                            actionName: "swipe",
                            startX:
                                clampValue(_startPoint.dx) * 2 * scaleFactor,
                            startY:
                                clampValue(_startPoint.dy) * 2 * scaleFactor,
                            endX: clampValue(_endPoint.dx) * 2 * scaleFactor,
                            endY: clampValue(_endPoint.dy) * 2 * scaleFactor,
                            duration:
                                (_endPoint - _startPoint).distance.round());
                        print("@@@@@@@@@@@@@@@@@@@@@ ");
                        print("startX : ${event.startX} ");
                        print("startY : ${event.startY} ");
                        print("endX : ${event.endX} ");
                        print("endY : ${event.endY} ");
                        channel!.sink.add(event.toJsonString());
                      },
                      child: Container(
                          alignment: Alignment.center,
                          color: Colors.blue,
                          width: double.infinity,
                          height: double.infinity,
                          child: StreamBuilder<dynamic>(
                            stream: imageStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data is Uint8List) {
                                return Image.memory(
                                  snapshot.data!,
                                  gaplessPlayback: true,
                                  height: double.infinity,
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                );
                              } else {
                                return const Text("waiting for device ...");
                              }
                            },
                          )),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      IconTextButton(
                                        onPressed: () {},
                                        text: "Stop Sharing",
                                        icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
