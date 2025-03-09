import 'dart:math';

import 'package:echo_share/configs/app_routes.dart';
import 'package:echo_share/models/swipe_event.dart';
import 'package:echo_share/models/tap_event.dart';
import 'package:echo_share/services/network_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DisplayPage extends StatefulWidget {
  final Size displaySize;
  const DisplayPage({super.key, required this.displaySize});

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  WebSocketChannel? channel;
  late Stream<Uint8List?> imageStream;
  Offset _startPoint = Offset.zero;
  Offset _endPoint = Offset.zero;
  bool _canSendControl = false;

  @override
  void initState() {
    super.initState();
    NetworkServices.instance.listen(onMessageRecieved);
    imageStream = NetworkServices.instance.map();
  }

  onMessageRecieved(dynamic message) {
    if (message is String && message == "EXIT") {
      Navigator.popUntil(
          context, (route) => route.settings.name == AppRoutes.welcome);
      return;
    }
  }

  double clampValue(double value) {
    return value > 0 ? value : 10;
  }

  double getScaleFactor(Size size) {
    return max(widget.displaySize.width / (size.width - 10),
        widget.displaySize.height / (size.height - 10));
  }

  @override
  void dispose() {
    NetworkServices.instance.close();
    super.dispose();
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
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: widget.displaySize.height / scaleFactor,
                    width: widget.displaySize.width / scaleFactor,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: GestureDetector(
                        onTapUp: (TapUpDetails details) {
                          final globalX =
                              details.localPosition.dx * 2 * scaleFactor;
                          final globalY =
                              details.localPosition.dy * 2 * scaleFactor;
                          final event = TapEvent(
                              actionName: "tap", x: globalX, y: globalY);
                          if (_canSendControl) {
                            NetworkServices.instance
                                .sendMessage(event.toJsonString());
                          }
                        },
                        onPanStart: (DragStartDetails details) {
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
                          if (_canSendControl) {
                            NetworkServices.instance
                                .sendMessage(event.toJsonString());
                          }
                        },
                        child: Container(
                            alignment: Alignment.center,
                            color: Colors.blue,
                            width: double.infinity,
                            height: double.infinity,
                            child: StreamBuilder<dynamic>(
                              stream: imageStream,
                              builder: (context, snapshot) {
                                _canSendControl = snapshot.hasData &&
                                    snapshot.data is Uint8List;
                                if (_canSendControl) {
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
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        FloatingActionButton(
                          onPressed: () {
                            NetworkServices.instance.sendMessage("EXIT");
                            Navigator.popUntil(
                                context,
                                (route) =>
                                    route.settings.name == AppRoutes.welcome);
                          },
                          shape: CircleBorder(),
                          backgroundColor: Colors.red,
                          mini: true,
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
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
