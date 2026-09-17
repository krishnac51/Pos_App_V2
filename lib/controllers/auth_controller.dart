import 'dart:async';

import 'package:get/get.dart';
import 'package:pos_v2/screens/auth/login/login_screen.dart';

import '../constants/api_urls.dart';
import '../core/services/api_services.dart';
import '../screens/auth/frogetPassword/otp_screen.dart';
import '../utils/error_message_helper.dart';
import '../utils/snakbar_helper.dart' show SnackbarHelper;

class AuthController extends GetxController {
  final ApiService api = Get.find<ApiService>();

  /// UI state
  RxBool showPassword = false.obs;
  RxBool showConfirmPassword = false.obs;
  RxInt secondsRemaining = 30.obs;
  RxBool enableResend = false.obs;
  RxBool isLoading = false.obs;
  Timer? _timer;

  /// Validation
  String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) return 'required_field'.tr;
    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'enter_otp'.tr;
    if (value.length != 6) return 'otp_six_digits'.tr;
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'required_field'.tr;
    if (value.length < 6) return 'password_min_six'.tr;
    return null;
  }

  /// OTP timer
  void startOtpTimer() {
    enableResend.value = false;
    secondsRemaining.value = 30;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        enableResend.value = true;
        timer.cancel();
      }
    });
  }

  /// Send OTP
  Future<void> sendOtp({
    required String userName,
    required bool isResend,
  }) async {
    if (!isResend) isLoading.value = true;

    try {
      final data = await api.post(
        ApiUrls.sendOtpUrl,
        body: {"username": userName},
        logoutOnUnauthorized: false,
      );

      if (data['success'] == true) {
        if (!isResend) {
          Get.to(() => OtpScreen(userName: userName));
        } else {
          SnackbarHelper.showSuccess('otp_sent_success'.tr);
        }
        startOtpTimer();
      } else {
        SnackbarHelper.showError(
          ErrorMessageHelper.responseMessage(
            data,
            fallbackKey: 'otp_send_failed',
          ),
        );
      }
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e);
    } catch (e) {
      SnackbarHelper.showApiError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify OTP
  Future<void> verifyOtp({
    required String userName,
    required String otp,
    required String password,
  }) async {
    isLoading.value = true;

    try {
      final data = await api.post(
        ApiUrls.verifyOtpUrl,
        body: {"username": userName, "otp": otp, "password": password},
        logoutOnUnauthorized: false,
      );

      if (data['success'] == true) {
        SnackbarHelper.showSuccess('password_updated'.tr);
        Get.offAll(LoginScreen());
      } else {
        SnackbarHelper.showError(
          ErrorMessageHelper.responseMessage(
            data,
            fallbackKey: 'otp_send_failed',
          ),
        );
      }
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e);
    } catch (e) {
      SnackbarHelper.showApiError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
