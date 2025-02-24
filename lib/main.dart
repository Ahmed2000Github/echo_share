import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
  static const platform = MethodChannel('screen_record');

  Future<void> startRecording() async {
    await requestPermissions();
    try {
      await platform.invokeMethod('startRecording');
    } on PlatformException catch (e) {
      print("Error starting recording: ${e.message}");
    }
  }

  Future<void> stopRecording() async {
    try {
      await platform.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      print("Error stopping recording: ${e.message}");
    }
  }

  static const platformChannel = const MethodChannel('test');
  Uint8List? _imageData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    platformChannel.setMethodCallHandler((call) async {
      var data = call.arguments as Uint8List;
      print("WWWWWWWWWWWWWWWWWWWWWWWWW: $data");
      // Process frameBytes (e.g., convert to an image widget)
      setState(() {
        _imageData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Screen Recorder")),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: startRecording,
              child: Text("Start Recording"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: stopRecording,
              child: Text("Stop Recording"),
            ),
            Expanded(
              child: Container(
                color: Colors.red,
                child: _imageData != null
                    ? Image.memory(
                        _imageData!,
                        fit: BoxFit.cover,
                        // width: 800,
                      )
                    : Text("Waiting for image..."),
              ),
            )
          ],
        ),
      ),
    );
  }
}
