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

  Future<void> startRecording() async {
    setState(() {
      _isrecording = true;
    });
    await requestPermissions();
    try {
      await currentChannel.invokeMethod('startRecording');
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

  static const platformChannel = const MethodChannel('test');
  Uint8List? _imageData;
  WebSocketChannel? channel;
  bool _isrecording = false;
  ValueNotifier<Uint8List?> imageNotifier = ValueNotifier<Uint8List?>(null);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    channel = WebSocketChannel.connect(
        Uri.parse('ws://eeb8-105-67-131-103.ngrok-free.app/ws'));

    if (Platform.isWindows) {
      channel?.stream.listen((res) {
        var data = res as Uint8List;
        // print(":::::::::::::::::::::::::::::::::::");
        imageNotifier.value = data;
      });
    } else if (Platform.isAndroid) {
      platformChannel.setMethodCallHandler((call) async {
        var data = call.arguments as Uint8List;
        if (channel != null && data.isNotEmpty) {
          channel!.sink.add(data);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Screen Recorder")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             ElevatedButton(
              onPressed: (){
                setState(() {
                    channel = WebSocketChannel.connect(
                      Uri.parse('ws://eeb8-105-67-131-103.ngrok-free.app/ws'));
                });
              },
              child: Text("connect"),
            ),
            if (!_isrecording&& Platform.isAndroid)
              ElevatedButton(
                onPressed: startRecording,
                child: Text("Start Recording"),
              ),
            if (_isrecording && Platform.isAndroid)
              ElevatedButton(
                onPressed: stopRecording,
                child: Text("Stop Recording"),
              ),
          
               if (Platform.isWindows) Expanded(
              child: Container(
                alignment: Alignment.center,
              child: ValueListenableBuilder<Uint8List?>(
                valueListenable: imageNotifier,
                builder: (context, imageData, child) {
                  if (imageData != null) {
                    return Image.memory(
                      imageData,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Text("Waiting for image...");
                  }
                },
              ),
            )
            )
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
