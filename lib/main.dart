// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:echo_share/configs/app_routes.dart';
import 'package:echo_share/configs/app_theme.dart';
import 'package:flutter/material.dart';


void main()  {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.welcome,
    );
  }
}
