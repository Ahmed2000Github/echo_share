import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkServices {
  static const String websoketURL = "echo-share-app.runasp.net";
  // static const String websoketURL = "localhost:5258";

  WebSocketChannel? channel;
  late Stream<dynamic> broadcastStream;

  static final NetworkServices instance = NetworkServices._internal();

  NetworkServices._internal();

  String connect(String ramdomToken) {
    if (channel != null ) {
      return ramdomToken ;
    }
    channel = WebSocketChannel.connect(Uri.parse("ws://$websoketURL/ws"));
    broadcastStream = channel!.stream.asBroadcastStream();
    channel!.sink.add(ramdomToken);
    return ramdomToken;
  }

  sendImage(Uint8List image) {
    // print("::::::::::::::::::::::::::::::::::: ${image.length}");
    if (channel != null && image.isNotEmpty) {
      channel!.sink.add(image);
    }
  }
  sendMessage(String message) {
    if (channel != null && message.isNotEmpty) {
      channel!.sink.add(message);
    }
  }

  listen(void Function(dynamic) callback) {
    broadcastStream.listen(callback);
  }

  Stream<Uint8List?> map() {
    return broadcastStream.map((data) {
      if (data is Uint8List) return data;
      return null;
    });
  }

  close() async {
    await channel?.sink.close();
    channel = null;
  }
}
