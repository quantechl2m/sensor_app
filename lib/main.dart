import 'package:esp32sensor/intro_slider.dart';
import 'package:esp32sensor/screens/home.dart';
import 'package:esp32sensor/services/auth.dart';
import 'package:esp32sensor/utils/constants/LocalString.dart';
import 'package:esp32sensor/utils/pojo/app_user.dart';
import 'package:esp32sensor/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(GetMaterialApp(
    translations: LocalString(),
    locale: const Locale('en', 'US'),
    debugShowCheckedModeBanner: false,
    routes: {
      '/intro': (context) => const IntroSliderPage(),
      '/home': (context) => const Homepage(),
    },
    home: StreamProvider<AppUser>.value(
        initialData: AppUser(uid: ""),
        value: AuthService().user,
        child: const Wrapper()),
    // initialRoute: RouteClass.getHomeRoute(),
    // getPages: RouteClass.routes,
    // routes: {
    //   "/":(context)=> Homepage(),
    //   "/gasSection":(context)=> GasPage(),
    //   "/waterSection":(context)=> waterPage(),
    //   "/soilSection":(context)=> soilPage(),
    // },
  ));
}
