import 'dart:math';

import 'package:echo_share/configs/app_colors.dart';
import 'package:echo_share/configs/app_routes.dart';
import 'package:echo_share/services/network_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodePageDesktop extends StatefulWidget {
  const QrCodePageDesktop({super.key});

  @override
  State<QrCodePageDesktop> createState() => _QrCodePageDesktopState();
}

class _QrCodePageDesktopState extends State<QrCodePageDesktop> {
  final ValueNotifier<String?> _tokenStatec = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    try {
      _tokenStatec.value =
          NetworkServices.instance.connect(generateRandomToken(40));
      //  _tokenStatec.value = NetworkServices.instance.connect("##@@##barcode.rawValue");
      NetworkServices.instance.listen(onMessageRecieved);
    } catch (e) {
      if (kDebugMode) {
        print("Connection Error: ${e.toString()}");
      }
    }
  }

  onMessageRecieved(dynamic message) {
    if (message is String && message.contains("ScreenSize:")) {
      final width = double.parse(message.split(":")[1]);
      final height = double.parse(message.split(":")[2]);
      final remoteSize = Size(width, height);
      Navigator.pushNamed(context, AppRoutes.display, arguments: remoteSize);
    }
  }

  generateRandomToken(int size) {
    const charatcters =
        "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbn1234567890!@#\$%^&*()_+";
    var randomValue = '';
    for (var i = 0; i < size; i++) {
      randomValue += charatcters[Random().nextInt(charatcters.length)];
    }
    return "##@@##$randomValue";
  }

  @override
  void dispose() {
    NetworkServices.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder(
                  valueListenable: _tokenStatec,
                  builder: (context, state, _) {
                    return state == null
                        ? CircularProgressIndicator(
                            color: AppColors.primary,
                          )
                        : ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFF29F39B),
                                  Color(0xFF01A1F9),
                                ], // Define your gradient colors
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: QrImageView(
                              data: state,
                              padding: const EdgeInsets.all(0),
                              version: QrVersions.auto,
                              size: 128.0,
                            ),
                          );
                  }),
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Scan the QR Code to Share Your Device Screen',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: theme.textButtonTheme.style!.copyWith(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(AppColors.error),
                  ),
                  child: const Text(
                    "Exit",
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
