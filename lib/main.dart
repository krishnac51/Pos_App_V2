// lib/main.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pos_v2/constants/api_urls.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:pos_v2/core/services/api_services.dart';
import 'package:pos_v2/core/services/notification_services.dart';
import 'package:pos_v2/firebase_option.dart';
import 'package:pos_v2/screens/splash_screen.dart';

import 'translation/app_translations.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  await GetStorage.init();
  Get.put(ApiService(baseUrl: ApiUrls.baseUrl));
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  await FirebaseCrashlytics.instance.recordError(
    Exception('Non-Fatal error'),
    null,
    fatal: false,
  );

  AppConstants.analytics = FirebaseAnalytics.instance;
  AppConstants.observer = FirebaseAnalyticsObserver(
    analytics: AppConstants.analytics!,
  );
  await NotificationService().initInfo();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Load saved locale or fallback to device locale
  Locale _initialLocale() {
    final box = GetStorage();
    final saved = box.read('locale');
    if (saved != null) {
      final parts = saved.split('_');
      return Locale(parts[0], parts.length > 1 ? parts[1] : null);
    }
    return const Locale('ar', 'AE');
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fosshati',
      supportedLocales: const [Locale("en", "US"), Locale("ar", 'AE')],
      localizationsDelegates: [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      translations: AppTranslations(),

      locale: _initialLocale(),
      fallbackLocale: const Locale("ar", "AE"),
      debugShowCheckedModeBanner: false,
      transitionDuration: Duration(milliseconds: 300),
      defaultTransition: Transition.native,
      theme: ThemeData(
        fontFamily: 'SF Pro',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          brightness: Brightness.light,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
