// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

setupMethodChannel() {
  const MethodChannel channel = MethodChannel('com.example.channel');

  channel.setMethodCallHandler((call) async {
    if (call.method == 'getDataFromFlutter') {
      return "Hello from Flutter! Received: ${call.arguments}";
    }
    return null;
  });
}

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // setupMethodChannel();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ScreenRecorderPage());
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

Future<void> requestPermissions() async {
  var status = await Permission.microphone.request();

  if (status.isGranted) {
    print("Microphone permission granted");
  } else {
    print("Microphone permission denied");
  }
}

class ScreenRecorderPage extends StatefulWidget {
  @override
  _ScreenRecorderPageState createState() => _ScreenRecorderPageState();
}

class _ScreenRecorderPageState extends State<ScreenRecorderPage> {
  static const currentChannel = MethodChannel('screen_record');
  late Stream<Uint8List?> imageStream;

  Future<void> startRecording() async {
    setState(() {
      _isrecording = true;
    });
    // await requestPermissions();
    try {
      await currentChannel.invokeMethod('startRecording', {
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
      await currentChannel.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print("Error stopping recording: ${e.message}");
    }
  }

  WebSocketChannel? channel;
  bool _isrecording = false;
  ValueNotifier<Uint8List?> imageNotifier = ValueNotifier<Uint8List?>(null);

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
      broadcastStream.listen((onData) {
        print(onData);
        if (onData is String) onEventAction(RemoteEvent.fromJsonString(onData));
      });

      currentChannel.setMethodCallHandler((call) async {
        var data = call.arguments as Uint8List;
        print("::::::::::::::::::::::::::::::::::: ${data.length}");
        if (channel != null && data.isNotEmpty) {
          channel!.sink.add(data);
        }
      });
    }
  }

  onEventAction(RemoteEvent event) async {
    const platform = MethodChannel('control_channel');
    try {
      await platform.invokeMethod('simulateTap', {'x': event.x, 'y': event.y});
    } on PlatformException catch (e) {
      print("Failed to simulate tap: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // print("ssssssssss");
    print(size.width);
    print(size.height);
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        final globalX = details.globalPosition.dx;
        final globalY = details.globalPosition.dy;
        final data = RemoteEvent(actionName: "tap", x: globalX, y: globalY)
            .toJsonString();
        print(data);
      },
      child: Scaffold(
        backgroundColor: Platform.isWindows ? Colors.grey : Colors.white,
        appBar:
            Platform.isAndroid ? AppBar(title: Text("Screen Recorder")) : null,
        body: Center(
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
                    child: Text("Start Recording"),
                  ),
                if (_isrecording && Platform.isAndroid)
                  ElevatedButton(
                    onPressed: stopRecording,
                    child: Text("Stop Recording"),
                  ),
                if (Platform.isWindows)
                  Expanded(
                    child: SingleChildScrollView(
                      child: GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          final globalX = details.localPosition.dx * 2;
                          final globalY = details.localPosition.dy * 2;
                          final data =
                              RemoteEvent(actionName: "tap", x: globalX, y: globalY)
                                  .toJsonString();
                          channel!.sink.add(data);
                        },
                        child: Container(
                            alignment: Alignment.center,
                            color: Colors.blue,
                            width: 360,
                            height: 800,
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
                                  return Text("waiting for device ...");
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
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }
}

class RemoteEvent {
  String actionName;
  double x;
  double y;
  RemoteEvent({
    required this.actionName,
    required this.x,
    required this.y,
  });
  String toJsonString() {
    return jsonEncode({
      'actionName': actionName,
      'x': x,
      'y': y,
    });
  }

  factory RemoteEvent.fromJsonString(String jsonString) {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    return RemoteEvent(
      actionName: jsonMap['actionName'],
      x: jsonMap['x'],
      y: jsonMap['y'],
    );
  }

  @override
  String toString() => 'RemoteEvent(actionName: $actionName, x: $x, y: $y)';
}
