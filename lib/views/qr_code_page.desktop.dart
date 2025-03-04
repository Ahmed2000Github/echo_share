import 'dart:math';

import 'package:echo_share/configs/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodePageDesktop extends StatelessWidget {
  const QrCodePageDesktop({Key? key}) : super(key: key);

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
              ShaderMask(
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
                  data: Random().nextInt(1000000).toString(),
                  padding: EdgeInsets.all(0),
                  version: QrVersions.auto,
                  size: 128.0,
                ),
              ),
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 300
                ),
                child: Text(
                  'Scan the QR Code to Share Your Device Screen',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
               SizedBox(height:20 ),
                TextButton(
                  onPressed: () {
                   Navigator.pop(context);
                  },
                   style: theme.textButtonTheme.style!.copyWith(
                    backgroundColor:  WidgetStateProperty.all<Color>(AppColors.error),
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
