import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/constants/api_urls.dart';
import 'package:pos_v2/core/services/api_services.dart'
    show ApiException, ApiService;

import '../constants/app_keys.dart';
import '../core/app_storage.dart';
import '../models/mobile_auth_model.dart';
import '../models/user_signup_model.dart';
import '../screens/home_screen.dart';
import '../utils/error_message_helper.dart';
import '../utils/snakbar_helper.dart';

class LoginController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;

  String get _languageCode => Get.locale?.languageCode == 'ar' ? 'ar' : 'en';

  String? validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your username or mobile number';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    final phoneNumber = value?.trim() ?? '';
    if (phoneNumber.isEmpty) return 'enter_mobile_number'.tr;
    if (!RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
      return 'mobile_number_10_digits'.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final data = await api.post(
        ApiUrls.loginUrl,
        body: {
          'username': username.trim(),
          'password': password,
          'lang': _languageCode,
        },
        logoutOnUnauthorized: false,
      );

      if (data is Map<String, dynamic> && data['success'] == true) {
        final model = UserSignupModel.fromJson(data);
        final accessToken = model.message?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          _showResponseError(data);
          return;
        }

        await AppStorage.writeString(AppKeys.userToken, accessToken);
        Get.offAll(() => HomeScreen());
      } else if (data is Map<String, dynamic>) {
        _showResponseError(data);
      }
    } on ApiException catch (error) {
      SnackbarHelper.showApiError(error);
    } catch (error) {
      SnackbarHelper.showApiError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<OtpChallenge?> loginWithPhone(String mobile) async {
    isLoading.value = true;
    try {
      final data = await api.post(
        ApiUrls.loginUrl,
        body: {'username': mobile, 'password': '', 'lang': _languageCode},
        logoutOnUnauthorized: false,
      );

      if (data is Map<String, dynamic> && data['success'] == true) {
        final challenge = OtpChallenge.fromResponse(
          data,
          fallbackMobile: mobile,
        );
        if (challenge.requestId.isEmpty) {
          _showResponseError(data);
          return null;
        }
        return challenge;
      }

      if (data is Map<String, dynamic>) _showResponseError(data);
      return null;
    } on ApiException catch (error) {
      SnackbarHelper.showApiError(error);
      return null;
    } catch (error) {
      SnackbarHelper.showApiError(error);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<OtpChallenge?> resendPhoneOtp(String mobile) async {
    try {
      final data = await api.post(
        ApiUrls.sendSmsUrl,
        body: {'mobile': mobile, 'lang': _languageCode},
        logoutOnUnauthorized: false,
      );

      if (data is Map<String, dynamic> && data['success'] == true) {
        final responseData = data['data'];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final requestId = payload['requestId']?.toString() ?? '';

        if (requestId.isEmpty) {
          _showResponseError(data);
          return null;
        }

        return OtpChallenge(
          isNewUser: false,
          mobile: mobile,
          requestId: requestId,
          otpSent: true,
          apiMessage: data['message'] is String
              ? data['message'] as String
              : null,
        );
      }

      if (data is Map<String, dynamic>) _showResponseError(data);
      return null;
    } on ApiException catch (error) {
      SnackbarHelper.showApiError(error);
      return null;
    } catch (error) {
      SnackbarHelper.showApiError(error);
      return null;
    }
  }

  Future<PhoneVerificationResult?> verifyPhoneOtp({
    required String mobile,
    required String activeKey,
    required String requestId,
  }) async {
    isLoading.value = true;
    try {
      final data = await api.post(
        ApiUrls.verifyLoginOtpUrl,
        body: {
          'mobile': mobile,
          'activeKey': activeKey,
          'requestId': requestId,
          'lang': _languageCode,
        },
        logoutOnUnauthorized: false,
      );

      if (data is Map<String, dynamic> && data['success'] == true) {
        final message = data['message'];
        if (message is Map && message['isNewUser'] == true) {
          return PhoneVerificationResult(
            isNewUser: true,
            mobile: message['mobile']?.toString() ?? mobile,
          );
        }

        final model = UserSignupModel.fromJson(data);
        final accessToken = model.message?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          _showResponseError(data);
          return null;
        }

        await AppStorage.writeString(AppKeys.userToken, accessToken);
        Get.offAll(() => HomeScreen());
        return PhoneVerificationResult(isNewUser: false, mobile: mobile);
      }

      if (data is Map<String, dynamic>) _showResponseError(data);
      return null;
    } on ApiException catch (error) {
      SnackbarHelper.showApiError(error);
      return null;
    } catch (error) {
      SnackbarHelper.showApiError(error);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void _showResponseError(Map<String, dynamic> response) {
    SnackbarHelper.showError(ErrorMessageHelper.responseMessage(response));
  }
}
