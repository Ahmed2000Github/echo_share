// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:echo_share/models/event.dart';

class SwipeEvent extends Event {
  String actionName;
  double startX;
  double startY;
  double endX;
  double endY;
  int duration;
  SwipeEvent({
    required this.actionName,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.duration,
  });

  String toJsonString() {
    return jsonEncode({
      'actionName': actionName,
      'startX': startX,
      'startY': startY,
      'endX': endX,
      'endY': endY,
      'duration': duration,
    });
  }

  factory SwipeEvent.fromJsonString(String jsonString) {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    return SwipeEvent(
      actionName: jsonMap['actionName'],
      startX: jsonMap['startX'],
      startY: jsonMap['startY'],
      endX: jsonMap['endX'],
      endY: jsonMap['endY'],
      duration: jsonMap['duration'],
    );
  }

  @override
  String toString() =>
      'SwipeEvent(actionName: $actionName, startX: $startX, startY: $startY, endX: $endX, endY: $endY, duration: $duration)';
}
