// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:echo_share/main.dart';
import 'package:echo_share/models/event.dart';

class TapEvent extends Event {
  String actionName;
  double x;
  double y;
  TapEvent({
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

  factory TapEvent.fromJsonString(String jsonString) {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    return TapEvent(
      actionName: jsonMap['actionName'],
      x: jsonMap['x'],
      y: jsonMap['y'],
    );
  }

  @override
  String toString() => 'TapEvent(actionName: $actionName, x: $x, y: $y)';
}
