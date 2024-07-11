import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'features/authentication/login_screen.dart';
import 'features/authentication/sign_up_screen.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/settings/settings_screen.dart';
import 'firebase_options.dart';
import 'features/home/widgets/tts_manager.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  KakaoSdk.init(nativeAppKey: '485169cb19d2eda65a5d36105f83a53b');
  Get.put(ThemeController()); // ThemeController 초기화
  runApp(MyApp(ttsManager: TtsManager()));
}

class MyApp extends StatelessWidget {
  final TtsManager ttsManager;

  MyApp({required this.ttsManager});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(() {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AIConnectCar',
        theme: ThemeData.dark().copyWith(
          primaryColor: themeController.primaryColor.value,
          hintColor: Colors.white,
          buttonTheme: ButtonThemeData(
            buttonColor: themeController.primaryColor.value,
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/sign_up': (context) => SignUpScreen(),
          '/home': (context) => HomeScreen(),
          '/settings': (context) => SettingsScreen(ttsManager: ttsManager),
        },
      );
    });
  }
}
