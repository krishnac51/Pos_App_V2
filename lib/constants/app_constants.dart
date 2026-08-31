import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pos_v2/constants/api_urls.dart';
import 'package:pos_v2/constants/app_keys.dart';
import 'package:pos_v2/controllers/bottom_nav_controller.dart';
import 'package:pos_v2/screens/auth/login/login_screen.dart';

import '../controllers/home_controller.dart';
import '../core/app_storage.dart';
import '../core/services/api_services.dart';
import '../models/app_config_model.dart';
import '../models/family_member_model.dart';
import '../models/user_model.dart';

class AppConstants {
  static Rxn<UserModel> currentUser = Rxn<UserModel>();
  static Rxn<UserModel> familyOwner = Rxn<UserModel>();
  static Rxn<FamilyMemberModel> familyMembers = Rxn<FamilyMemberModel>();
  static final storage = GetStorage();
  static FirebaseAnalytics? analytics;
  static FirebaseAnalyticsObserver? observer;
  static String fcmToken = "";
  static String paymentBaseUrl = "";
  static String paymentApiKey = "";
  static double minRecharge = 0;

  static void saveConfig(AppConfig config) {
    paymentBaseUrl = config.message?.paymentBaseUrl ?? "";
    paymentApiKey = config.message?.paymentApiKey ?? "";
    minRecharge = config.message?.minRecharge ?? 0;
  }

  // static String ottuApiKey = "GYj5Na8H.29g9hqNjm11nORQMa2WiZwIBQQ49MdAL";
  static String ottuMerchantId = "online.fosshati.com.sa";
  static final checkoutHeight = ValueNotifier(300);
  static RxString currentBalance = "0.0".obs;
  static Future<void> logoutUser() async {
    await storage.remove(AppKeys.userToken);
    if (Get.isRegistered<HomeController>()) {
      Get.delete<HomeController>(force: true);
    }
    if (Get.isRegistered<BottomNavController>()) {
      Get.delete<BottomNavController>(force: true);
    }
    // Navigate to Login
    Get.offAll(() => const LoginScreen());
  }

  static Future<void> logout() async {
    final ApiService api = Get.find<ApiService>();
    try {
      final headers = await getAuthHeaders();
      await api.post(
        ApiUrls.logoutUrl,
        headers: headers,
        body: {"fcm_token": AppConstants.fcmToken},
      );
    } catch (e) {
      print("Logout API error: $e");
    } finally {
      await logoutUser();
    }
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    String token = AppStorage.readString(AppKeys.userToken);

    if (token.isEmpty) {
      await logoutUser();

      return {"Content-Type": "application/json"};
    }
    print("user token= Bearer $token");
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  static double safeParseBalance(String? value) {
    if (value == null || value.trim().isEmpty) return 0.0;

    try {
      return double.parse(value);
    } catch (e) {
      return 0.0; // fallback if value is invalid
    }
  }

  static double parseToDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;

    return defaultValue;
  }
}
