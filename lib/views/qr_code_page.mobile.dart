import 'package:echo_share/configs/app_routes.dart';
import 'package:echo_share/views/widgets/q_r_scanner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodePageMobile extends StatefulWidget {
  const QrCodePageMobile({super.key});

  @override
  State<QrCodePageMobile> createState() => _QrCodePageMobileState();
}

class _QrCodePageMobileState extends State<QrCodePageMobile> {
  late MobileScannerController cameraController;

  final ValueNotifier<bool> _torchState = ValueNotifier<bool>(false);
  bool _codeDetected = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Navigator.pushNamed(context, AppRoutes.recordPage,
    //                   arguments: "##@@##barcode.rawValue");
    // });
  }

  Rect _getScanWindow(Size size) {
    final scanWindowWidth = size.width * 0.8;
    return Rect.fromLTWH(
      (size.width - scanWindowWidth) / 2,
      (size.height - scanWindowWidth) / 2,
      scanWindowWidth,
      scanWindowWidth,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _torchState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindow = _getScanWindow(size);
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            scanWindow: scanWindow,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (!_codeDetected) {
                  _codeDetected = true;
                  Navigator.pushNamed(context, AppRoutes.recordPage,
                      arguments: barcode.rawValue);
                }
              }
            },
          ),
          QRScannerOverlay(overlayColour: Colors.white.withOpacity(0.5)),
          SafeArea(
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _torchState,
                    builder: (context, state, child) {
                      return !state
                          ? const Icon(Icons.flash_off, color: Colors.blueGrey)
                          : const Icon(Icons.flash_on, color: Colors.white);
                    },
                  ),
                  onPressed: () async {
                    await cameraController.toggleTorch();
                    _torchState.value = !_torchState.value;
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
