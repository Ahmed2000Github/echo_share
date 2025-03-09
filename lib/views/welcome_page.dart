import 'dart:io';

import 'package:echo_share/configs/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid){
       requestCameraPermission();
    }
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
     final status =  await Permission.camera.request();
     if (status != PermissionStatus.granted) {
        SystemChannels.platform.invokeMethod("SystemNavigator.pop");
     }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final width = MediaQuery.of(context).size.width;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) SystemChannels.platform.invokeMethod("SystemNavigator.pop");
      },
      child: Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 350),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome to",
                  style: theme.textTheme.titleLarge,
                ),
                Image.asset("assets/images/logo.png"),
                Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: Text(
                    "Where you can easily share and control your Android device screen on your desktop.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                TextButton(
                    onPressed: () {
                      if (Platform.isAndroid) {
                        Navigator.pushNamed(context, AppRoutes.qrCodeMobile);
                      } else if (Platform.isWindows) {
                        Navigator.pushNamed(context, AppRoutes.qrCodeDesktop);
                      }
                    },
                    child: const Text(
                      "Get Started",
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
