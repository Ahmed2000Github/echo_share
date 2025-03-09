import 'package:echo_share/views/display_page.dart';
import 'package:echo_share/views/not_found.dart';
import 'package:echo_share/views/qr_code_page.desktop.dart';
import 'package:echo_share/views/qr_code_page.mobile.dart';
import 'package:echo_share/views/welcome_page.dart';
import 'package:echo_share/views/record_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String welcome = "/welcome";
  static const String qrCodeDesktop = "/qrCodeDesktop";
  static const String qrCodeMobile = "/qrCodeMobile";
  static const String display = "/display";
  static const String recordPage = "/recordPage";
  static const String notFound = "/notFound";
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;
    bool isLeftSliding = false;
    switch (settings.name) {
      case AppRoutes.welcome:
        isLeftSliding = true;
        page = const WelcomePage();
        break;
      case AppRoutes.qrCodeDesktop:
        page = const QrCodePageDesktop();
        break;

      case AppRoutes.qrCodeMobile:
        page = QrCodePageMobile();
        break;
      case AppRoutes.display:
        page =  DisplayPage(displaySize: settings.arguments as Size,);
        break;
      case AppRoutes.recordPage:
      
        page = RecordPage(
          token: settings.arguments as String,
        );
        break;

      default:
        page = const NotFound();
    }
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin =
            isLeftSliding ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
