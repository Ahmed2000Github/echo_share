// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:math';

import 'package:echo_share/configs/app_routes.dart';
import 'package:echo_share/configs/app_theme.dart';
import 'package:echo_share/models/event.dart';
import 'package:echo_share/models/swipe_event.dart';
import 'package:echo_share/models/tap_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


void main()  {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.welcome,
    );
  }
}

// class ScreenWebRtcPage extends StatefulWidget {
//   const ScreenWebRtcPage({super.key});

//   @override
//   State<ScreenWebRtcPage> createState() => _ScreenWebRtcPageState();
// }

// class _ScreenWebRtcPageState extends State<ScreenWebRtcPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: RTCVideoView(_renderer),
//     );
//   }
// }

// Future<void> requestPermissions() async {
//   var status = await Permission.microphone.request();

//   if (status.isGranted) {
//     print("Microphone permission granted");
//   } else {
//     print("Microphone permission denied");
//   }
// }

class ScreenRecorderPage extends StatefulWidget {
  @override
  _ScreenRecorderPageState createState() => _ScreenRecorderPageState();
}

class _ScreenRecorderPageState extends State<ScreenRecorderPage> {
  static const recordChannel = MethodChannel('screen_record');
  static const controlChannel = MethodChannel('control_channel');
  late Stream<Uint8List?> imageStream;
  Offset _startPoint = Offset.zero;
  Offset _endPoint = Offset.zero;

  Future<void> checkAccessibilityService() async {
    try {
      final bool result =
          await controlChannel.invokeMethod('checkAccessibilityService');
      print("ttttttttttttttttttttt $result");
      if (!result) {
        openAccessibilitySettings();
      }
    } on PlatformException catch (e) {
      print("Failed to check accessibility service: '${e.message}'.");
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      final result =
          await controlChannel.invokeMethod('openAccessibilitySettings');
      print("fffffffffffffffffffff $result");
    } on PlatformException catch (e) {
      // Handle platform exceptions
      print("Failed to open accessibility settings: '${e.message}'.");
    }
  }

  Future<void> startRecording() async {
    setState(() {
      _isrecording = true;
    });
    // await requestPermissions();
    try {
      await recordChannel.invokeMethod('startRecording', {
        'width': 800,
        'height': 360,
      });
    } on PlatformException catch (e) {
      print("Error starting recording: ${e.message}");
    }
  }

  Future<void> stopRecording() async {
    setState(() {
      _isrecording = false;
    });
    try {
      await recordChannel.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print("Error stopping recording: ${e.message}");
    }
  }

  WebSocketChannel? channel;
  bool _isrecording = false;
  ValueNotifier<Uint8List?> imageNotifier = ValueNotifier<Uint8List?>(null);
  ValueNotifier<bool> _switch = ValueNotifier<bool>(false);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:5258/ws'));
    final broadcastStream = channel!.stream.asBroadcastStream();
    if (Platform.isWindows) {
      imageStream = broadcastStream.map((data) {
        if (data is Uint8List) return data;
        return null;
      });
    } else if (Platform.isAndroid) {
      checkAccessibilityService();
      broadcastStream.listen((onData) {
        // print(onData);
        if (onData.contains('tap')) {
          onEventAction(TapEvent.fromJsonString(onData));
        } else {
          onEventAction(SwipeEvent.fromJsonString(onData));
        }
      });

      recordChannel.setMethodCallHandler((call) async {
        var data = call.arguments as Uint8List;
        print("::::::::::::::::::::::::::::::::::: ${data.length}");
        if (channel != null && data.isNotEmpty) {
          channel!.sink.add(data);
        }
      });
    }
  }

  final SwipeEvent swipeLeft = SwipeEvent(
      actionName: "Swipe Left",
      startX: 12.249999999999993,
      startY: 125.00000000000003,
      endX: 114.75,
      endY: 135.00000000000003,
      duration: 137);
  final SwipeEvent swipeRight = SwipeEvent(
      actionName: "Swipe Left",
      startX: 320.5,
      startY: 336.0,
      endX: 18.499999999999986,
      endY: 337.0,
      duration: 137);

  onEventAction(Event event) async {
    try {
      if (event is TapEvent) {
        await controlChannel
            .invokeMethod('simulateTap', {'x': event.x, 'y': event.y});
      } else if (event is SwipeEvent) {
        // print("&&&&&&&&&&&&&&&&&");
        // print("startX : ${event.startX / 2} ");
        // print("startY : ${event.startY / 2} ");
        // print("endX : ${event.endX / 2} ");
        // print("endY : ${event.endY / 2} ");
        // print("duration : ${event.duration} ");
        if (event.actionName == "SL") {
          event = swipeLeft;
        }

        await controlChannel.invokeMethod('simulateSwipe', {
          'startX': event.startX,
          'startY': event.startY,
          'endX': event.endX,
          'endY': event.endY,
          'duration': event.duration,
        });
      }
    } on PlatformException catch (e) {
      print("Failed to simulate event: '${e.message}'.");
    }
  }

  double clampValue(double value) {
    return value > 0 ? value : 10;
  }

  final remoteSize = const Size(360, 800);
  double getScaleFactor(Size size) {
    return max(remoteSize.width / (size.width - 10),
        remoteSize.height / (size.height - 10));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // print("ssssssssss");
    // print(size.width);
    // print(size.height);

    final scaleFactor = getScaleFactor(size);
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        final globalX = details.globalPosition.dx;
        final globalY = details.globalPosition.dy;
        final data =
            TapEvent(actionName: "tap", x: globalX, y: globalY).toJsonString();
        if (Platform.isAndroid) print(data);
      },
      onPanStart: (details) {
        // print("!!!!!!!!!!!ssss ${details.globalPosition}");
        if (Platform.isAndroid) {
          print("@@@@@@@@@@@@@@@@@@@@@ ");
          print("startX : ${details.globalPosition.dx} ");
          print("startY : ${details.globalPosition.dy} ");
        }
      },
      onPanEnd: (DragEndDetails details) {
        // print("!!!!!!!!!!! ${details.globalPosition}");
        if (Platform.isAndroid) {
          print("endX : ${details.globalPosition.dx} ");
          print("endY : ${details.globalPosition.dy} ");
        }
      },
      child: Scaffold(
        backgroundColor: Platform.isWindows ? Colors.grey : Colors.white,
        appBar: Platform.isAndroid
            ? AppBar(title: const Text("Screen Recorder"))
            : null,
        body: Stack(
          children: [
            Center(
              child: Container(
                color: Colors.red,
                width: size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ElevatedButton(
                    //   onPressed: () {
                    //     setState(() {
                    //       channel = WebSocketChannel.connect(
                    //           Uri.parse('ws://localhost:5258/ws'));
                    //       //  channel!.sink.add('data');
                    //     });
                    //   },
                    //   child: Text("connect"),
                    // ),
                    if (!_isrecording && Platform.isAndroid)
                      ElevatedButton(
                        onPressed: startRecording,
                        child: const Text("Start Recording"),
                      ),
                    if (_isrecording && Platform.isAndroid)
                      ElevatedButton(
                        onPressed: stopRecording,
                        child: const Text("Stop Recording"),
                      ),
                    if (Platform.isWindows)
                      SizedBox(
                        height: remoteSize.height / scaleFactor,
                        width: remoteSize.width / scaleFactor,
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: GestureDetector(
                            onTapUp: (TapUpDetails details) {
                              final globalX = details.localPosition.dx;
                              final globalY = details.localPosition.dy;
                              final event = TapEvent(
                                  actionName: "tap", x: globalX, y: globalY);
                              print(
                                  "&&&&&&&&&&&&&&&&&&&& ${event.toJsonString()}");
                              event.x =
                                  details.localPosition.dx * 2 * scaleFactor;
                              event.y =
                                  details.localPosition.dy * 2 * scaleFactor;
                              print(
                                  "@@@@@@@@@@@@@@@@@@@@@ ${event.toJsonString()}");
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
                                  startX: clampValue(_startPoint.dx) *
                                      2 *
                                      scaleFactor,
                                  startY: clampValue(_startPoint.dy) *
                                      2 *
                                      scaleFactor,
                                  endX: clampValue(_endPoint.dx) *
                                      2 *
                                      scaleFactor,
                                  endY: clampValue(_endPoint.dy) *
                                      2 *
                                      scaleFactor,
                                  duration: (_endPoint - _startPoint)
                                      .distance
                                      .round());
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
                                      return const Text(
                                          "waiting for device ...");
                                    }
                                  },
                                )),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
            Positioned(
                child: GestureDetector(
              onTap: () {
                _switch.value = !_switch.value;
              },
              child: ValueListenableBuilder(
                  valueListenable: _switch,
                  builder: (BuildContext context, bool value, Widget? child) {
                    return Container(
                      width: 10,
                      height: 10,
                      color: _switch.value ? Colors.white : Colors.black,
                    );
                  }),
            ))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }
}
