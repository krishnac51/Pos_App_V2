import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pos_v2/constants/api_urls.dart' show ApiUrls;
import 'package:pos_v2/constants/app_keys.dart';
import 'package:pos_v2/controllers/bottom_nav_controller.dart';

import '../constants/app_constants.dart';
import '../core/app_storage.dart';
import '../core/services/api_services.dart';
import '../models/get_all_store_response_model.dart';
import '../models/user_signup_model.dart';
import '../screens/home_screen.dart';
import '../utils/snakbar_helper.dart';
import 'home_controller.dart';

class RegisterController extends GetxController {
  final api = Get.find<ApiService>();
  final RxInt _currentStep = 0.obs;
  bool isFamilyMember = false;
  int get currentStep => _currentStep.value;
  set currentStep(int value) => _currentStep.value = value;
  UserSignupModel? signedUpUser;
  UserSignupModel? familyMember;
  void nextStep() => _currentStep.value++;
  void previousStep() => _currentStep.value--;
  void setStep(int step) => _currentStep.value = step;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final govIdController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  var selectedImagePath = "".obs;
  final addressController = TextEditingController();
  final allergiesController = TextEditingController();

  RxBool isStoreLoading = false.obs;
  RxBool creatingUser = false.obs;
  RxBool uploadingImage = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  Rx<DateTime?> dob = Rx<DateTime?>(null);
  final RxString selectedStore = ''.obs;
  final RxString selectedTenantId = ''.obs;
  final RxList<Stores> stores = <Stores>[].obs;

  final List<String> countries = ['USA', 'Canada', 'UK', 'Australia'];

  @override
  void onInit() {
    super.onInit();
    getAllStore();
  }

  String get formattedDob {
    if (dob.value == null) return '';
    return DateFormat('yyyy-MM-dd').format(dob.value!);
  }

  // Validators
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'enter_email'.tr;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'invalid_email'.tr;
    }
    return null;
  }

  /// Optional email: empty is valid; if provided, must be valid format
  String? validateOptionalEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'invalid_email'.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'enter_password'.tr;
    if (value.length < 6) return 'min_6_characters'.tr;
    return null;
  }

  String? validateRequired(String? value, String fieldNameKey) {
    if (value == null || value.isEmpty)
      return '${fieldNameKey.tr} ${'is_required'.tr}';
    return null;
  }

  String? validateGovId(String? value) {
    if (value == null || value.isEmpty) {
      return 'gov_id_required'.tr;
    }

    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(value)) {
      return 'gov_id_numbers_only'.tr;
    }
    if (value.length != 10) {
      return 'gov_id_10_digits'.tr;
    }

    return null;
  }

  Future<void> getAllStore() async {
    try {
      isStoreLoading.value = true;
      final data = await api.get(ApiUrls.getStoreUrl);

      if (data['success'] == true) {
        final model = GetAllStoreResponseModel.fromJson(data);
        stores.value = model.message?.stores ?? [];
        reorderStoresForParent();
      } else {
        stores.clear();
        SnackbarHelper.showError(
          data['message']?? 'error_fetching_stores'.tr,
        );
      }
    } on ApiException catch (e) {
      stores.clear();
      SnackbarHelper.showApiError(e, fallbackKey: 'error_fetching_stores');
    } catch (e) {
      stores.clear();
      SnackbarHelper.showError('unexpected_error'.tr);
    } finally {
      isStoreLoading.value = false;
    }
  }

  void reorderStoresForParent() {
    final parentTenantId = AppConstants.currentUser.value?.userData?.tenantId;
    if (isFamilyMember && parentTenantId != null && parentTenantId.isNotEmpty) {
      if (stores.isNotEmpty) {
        final storeList = List<Stores>.from(stores);
        final index = storeList.indexWhere((s) => s.tenantId == parentTenantId);
        if (index != -1) {
          final parentStore = storeList.removeAt(index);
          storeList.insert(0, parentStore);
          stores.value = storeList;
        }
      }
      if (selectedTenantId.value.isEmpty) {
        selectedTenantId.value = parentTenantId;
      }
    }
  }

  Future<bool> registerUser() async {
    bool isSuccess = false;
    try {
      creatingUser.value = true;

      final body = {
        "tenant_id": selectedTenantId.value,
        "parent_id": null,
        "name": nameController.text.trim(),
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "gov_id": govIdController.text.trim(),
        "phone": phoneController.text.trim(),
        "country": 'Riyad',
        "city": 'Riyad',
        "address": addressController.text.trim(),
        "allergies": allergiesController.text.trim(),
        "dob": formattedDob,
        "password": passwordController.text.trim(),
      };

      debugPrint("=== [REGISTER API REQUEST] ===");
      debugPrint("URL: ${ApiUrls.registerUrl}");
      debugPrint("BODY: $body");

      final response = await api.post(ApiUrls.registerUrl, body: body);

      debugPrint("=== [REGISTER API RESPONSE] ===");
      debugPrint("RESPONSE: $response");

      if (response['success'] == true) {
        final model = UserSignupModel.fromJson(response);
        signedUpUser = model;
        await AppStorage.writeString(
          AppKeys.userToken,
          signedUpUser!.message!.accessToken!,
        );
        isSuccess = true;
        return isSuccess;
      } else {
        debugPrint("=== [REGISTER API FAILED] ===");
        debugPrint("Message: ${response['message']}");
        SnackbarHelper.showError(
          response['message'] ?? 'error_creating_account'.tr,
        );
        return isSuccess;
      }
    } on ApiException catch (e) {
      debugPrint("=== [REGISTER API ERROR - ApiException] ===");
      debugPrint("Message: ${e.message}, StatusCode: ${e.statusCode}, Data: ${e.data}");
      SnackbarHelper.showApiError(e, fallbackKey: 'error_creating_account');
      return isSuccess;
    } catch (e, stackTrace) {
      debugPrint("=== [REGISTER API ERROR - Catch] ===");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
      SnackbarHelper.showError('unexpected_error'.tr);
      return isSuccess;
    } finally {
      creatingUser.value = false;
    }
  }

  Future<bool> addFamilyMember() async {
    bool isSuccess = false;
    try {
      creatingUser.value = true;

      final body = {
        "tenant_id": selectedTenantId.value.isNotEmpty
            ? selectedTenantId.value
            : AppConstants.currentUser.value!.userData!.tenantId ?? "",
        "parent_id": AppConstants.currentUser.value!.userData!.id ?? "",
        "name": nameController.text.trim(),
        "username": usernameController.text.trim(),
        if (emailController.text.trim().isNotEmpty)
          "email": emailController.text.trim(),
        "gov_id": govIdController.text.trim(),
        "phone": phoneController.text.trim(),
        "country": 'Riyad',
        "city": 'Riyad',
        "address": addressController.text.trim(),
        "allergies": allergiesController.text.trim(),
        "dob": formattedDob,
        "password": passwordController.text.trim(),
      };

      debugPrint("=== [ADD FAMILY MEMBER API REQUEST] ===");
      debugPrint("URL: ${ApiUrls.registerUrl}");
      debugPrint("BODY: $body");

      final response = await api.post(ApiUrls.registerUrl, body: body);

      debugPrint("=== [ADD FAMILY MEMBER API RESPONSE] ===");
      debugPrint("RESPONSE: $response");

      if (response['success'] == true) {
        final model = UserSignupModel.fromJson(response);
        familyMember = model;
        isSuccess = true;
        return isSuccess;
      } else {
        debugPrint("=== [ADD FAMILY MEMBER API FAILED] ===");
        debugPrint("Message: ${response['message']}");
        SnackbarHelper.showError(
          response['message'] ?? 'error_creating_account'.tr,
        );
        return isSuccess;
      }
    } on ApiException catch (e) {
      debugPrint("=== [ADD FAMILY MEMBER API ERROR - ApiException] ===");
      debugPrint("Message: ${e.message}, StatusCode: ${e.statusCode}, Data: ${e.data}");
      SnackbarHelper.showApiError(e, fallbackKey: 'error_creating_account');
      return isSuccess;
    } catch (e, stackTrace) {
      debugPrint("=== [ADD FAMILY MEMBER API ERROR - Catch] ===");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
      SnackbarHelper.showError('unexpected_error'.tr);
      return isSuccess;
    } finally {
      creatingUser.value = false;
    }
  }

  Future<void> uploadUserProfileImage({required bool isFamilyMember}) async {
    try {
      uploadingImage.value = true;
      if (selectedImagePath.value.isEmpty) {
        SnackbarHelper.showError("select_image".tr);
        return;
      }
      final imageFile = File(selectedImagePath.value);
      Map<String, String> headers;

      if (isFamilyMember) {
        headers = {
          "Authorization": "Bearer ${familyMember!.message!.accessToken}",
        };
      } else {
        headers = await AppConstants.getAuthHeaders();
      }

      debugPrint("=== [UPLOAD PROFILE IMAGE API REQUEST] ===");
      debugPrint("URL: ${ApiUrls.uploadProfileImage}");
      debugPrint("Headers: $headers");
      debugPrint("FilePath: ${imageFile.path}");

      final response = await api.postMultipart(
        ApiUrls.uploadProfileImage,
        files: {"image": imageFile},
        headers: headers,
      );

      debugPrint("=== [UPLOAD PROFILE IMAGE API RESPONSE] ===");
      debugPrint("RESPONSE: $response");

      if (response['success'] == true) {
        SnackbarHelper.showSuccess("profile_image_uploaded".tr);
        if (isFamilyMember) {
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().getFamilyMember();
          }
          if (Get.isRegistered<BottomNavController>()) {
            Get.find<BottomNavController>().changeIndex(0);
          }
        }

        Get.offAll(HomeScreen());
      } else {
        debugPrint("=== [UPLOAD PROFILE IMAGE API FAILED] ===");
        debugPrint("Message: ${response['message']}");
        SnackbarHelper.showError(
          response['message'] ?? 'error_upload_image'.tr,
        );
      }
    } catch (e, stackTrace) {
      debugPrint("=== [UPLOAD PROFILE IMAGE API ERROR] ===");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");
      SnackbarHelper.showError('unexpected_error'.tr);
    } finally {
      uploadingImage.value = false;
    }
  }
}
