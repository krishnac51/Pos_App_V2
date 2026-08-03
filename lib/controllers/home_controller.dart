import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pos_v2/constants/api_urls.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:pos_v2/models/family_member_model.dart' hide Message;
import 'package:pos_v2/models/user_model.dart';

import '../core/services/analytics_services.dart';
import '../core/services/api_services.dart';
import '../models/app_config_model.dart' show AppConfig;
import '../models/user_sales_model.dart';
import '../utils/app_utils.dart';
import '../utils/error_message_helper.dart';
import '../utils/snakbar_helper.dart';

class HomeController extends GetxController {
  final api = Get.find<ApiService>();
  RxBool isUserLoading = false.obs;
  RxBool isOwnerLoading = false.obs;
  RxInt deletingMemberId = (-1).obs;
  RxBool isFamilyLoading = false.obs;
  RxBool isSaleLoading = false.obs;
  RxBool isLoadMore = false.obs;

  /// Set when getFamilyMember fails; null when success or not yet loaded.
  final familyError = Rxn<String>();

  /// Set when getUserSales fails (initial load); null when success or not yet loaded.
  final salesError = Rxn<String>();
  UserSalesModel? sales;

  Rxn<UserSalesModel> memberSales = Rxn<UserSalesModel>();
  int currentPage = 1;
  int perPage = 10;
  bool hasMorePages = true;

  /// TODO(PLAYSTORE_SS): set to `false` / remove after Play Store screenshots.
  static const bool useDummyRecentOrders = true;

  @override
  Future<void> onInit() async {
    super.onInit();
    fetchAppConfigs();
    await getUserData();
    getUserSales();
    getCurrentBalance();
    _sendFcmTokenToServer();
    AnalyticsService.logScreen(screenName: 'HomeScreen');
  }

  var isMemberSaleLoading = false.obs;
  var isMemberLoadMore = false.obs;
  int memberCurrentPage = 1;
  bool memberHasMorePages = true;
  int? currentMemberId;
  Future<void> fetchAppConfigs() async {
    try {
      final headers = await AppConstants.getAuthHeaders();

      final data = await api.get(ApiUrls.configsUrl, headers: headers);

      print("✅ Config API Response: $data");

      final configModel = AppConfig.fromJson(data);

      if (configModel.success == true) {
        // ✅ Save in AppConstants
        AppConstants.saveConfig(configModel);

        print("✅ Config Saved Successfully");
        print("Base URL: ${AppConstants.paymentBaseUrl}");
        print("API Key: ${AppConstants.paymentApiKey}");
        print("Min Recharge: ${AppConstants.minRecharge}");
      }
    } catch (e) {
      print("❌ Config API Error: $e");
    }
  }

  Future<void> getMemberSales({
    required int customerId,
    bool loadMore = false,
  }) async {
    if (currentMemberId != customerId || !loadMore) {
      memberCurrentPage = 1;
      memberHasMorePages = true;
      memberSales.value = null;
    }

    currentMemberId = customerId;

    if (!memberHasMorePages) return;

    try {
      if (loadMore) {
        isMemberLoadMore.value = true;
      } else {
        isMemberSaleLoading.value = true;
      }

      final headers = await AppConstants.getAuthHeaders();
      final data = await api.get(
        ApiUrls.getSalesUrl,
        headers: headers,
        queryParameters: {
          "customer_id": customerId.toString(),
          "page": memberCurrentPage.toString(),
          "per_page": perPage.toString(),
        },
      );

      if (data['success'] == true) {
        final model = UserSalesModel.fromJson(data);

        if (loadMore && memberSales.value!.message != null) {
          memberSales.value!.message!.data?.addAll(model.message?.data ?? []);
          memberSales.value!.message!.pagination = model.message?.pagination;
          memberSales.refresh(); // Trigger UI update
        } else {
          memberSales.value = model;
        }

        memberCurrentPage =
            (model.message?.pagination?.currentPage ?? memberCurrentPage) + 1;
        memberHasMorePages =
            memberCurrentPage <=
            (model.message?.pagination?.lastPage ?? memberCurrentPage);
      } else {
        SnackbarHelper.showError(
          data['message'] ?? "Error loading member sales",
        );
      }
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e);
    } catch (e) {
      SnackbarHelper.showApiError(e);
    } finally {
      isMemberSaleLoading.value = false;
      isMemberLoadMore.value = false;
    }
  }

  Future<void> loadNextMemberPage(int customerId) async {
    if (memberHasMorePages &&
        !isMemberSaleLoading.value &&
        !isMemberLoadMore.value) {
      await getMemberSales(customerId: customerId, loadMore: true);
    }
  }

  String formatOrderDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _sendFcmTokenToServer() async {
    try {
      final headers = await AppConstants.getAuthHeaders();
      final deviceId = DeviceUtils.getDeviceId();
      // final fcmToken = await DeviceUtils.getFcmToken();

      final body = {
        "platform": DeviceUtils.getPlatform(),
        "device_id": deviceId,
        "fcm_token": AppConstants.fcmToken,
      };

      final data = await api.post(
        ApiUrls.saveFcmToken,
        headers: headers,
        body: body,
      );
      print("FCM token sent successfully: $data");
    } finally {}
  }

  Future<void> getUserSales({bool loadMore = false}) async {
    if (!loadMore) {
      currentPage = 1;
      hasMorePages = true;
      salesError.value = null;
    }

    if (!hasMorePages) return;

    // TODO(PLAYSTORE_SS): remove this block after screenshots
    if (useDummyRecentOrders) {
      if (loadMore) return;
      isSaleLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 300));
      sales = _dummyRecentOrders();
      hasMorePages = false;
      salesError.value = null;
      isSaleLoading.value = false;
      update();
      return;
    }

    try {
      if (loadMore) {
        isLoadMore.value = true;
      } else {
        isSaleLoading.value = true;
      }

      final headers = await AppConstants.getAuthHeaders();

      final data = await api.get(
        ApiUrls.getSalesUrl,
        headers: headers,
        queryParameters: {
          "page": currentPage.toString(),
          "per_page": perPage.toString(),
        },
      );

      if (data['success'] == true) {
        final model = UserSalesModel.fromJson(data);

        if (loadMore && sales != null && sales!.message != null) {
          // Append new data
          sales!.message!.data?.addAll(model.message?.data ?? []);
          sales!.message!.pagination = model.message?.pagination;
        } else {
          sales = model;
        }

        // Update pagination
        currentPage =
            (model.message?.pagination?.currentPage ?? currentPage) + 1;
        hasMorePages =
            currentPage <= (model.message?.pagination?.lastPage ?? currentPage);
      } else {
        final msg = data['message']?.toString() ?? 'error_loading_orders'.tr;
        if (!loadMore) salesError.value = msg;
        SnackbarHelper.showError(
          ErrorMessageHelper.toUserMessage(
            ApiException(message: msg, data: null),
            fallbackKey: 'error_loading_orders',
          ),
        );
      }
    } on ApiException catch (e) {
      final msg = ErrorMessageHelper.toUserMessage(
        e,
        fallbackKey: 'error_loading_orders',
      );
      if (!loadMore) salesError.value = msg;
      SnackbarHelper.showApiError(e, fallbackKey: 'error_loading_orders');
    } catch (e) {
      final msg = ErrorMessageHelper.toUserMessage(
        e,
        fallbackKey: 'error_loading_orders',
      );
      if (!loadMore) salesError.value = msg;
      SnackbarHelper.showApiError(e, fallbackKey: 'error_loading_orders');
    } finally {
      if (loadMore) {
        isLoadMore.value = false;
      } else {
        isSaleLoading.value = false;
      }
    }
  }

  Future<void> getUserData() async {
    try {
      isUserLoading.value = true;

      final headers = await AppConstants.getAuthHeaders();
      final data = await api.get(ApiUrls.getProfileUrl, headers: headers);

      if (data['success'] == true) {
        final model = UserModel.fromJson(data);
        AppConstants.currentUser.value = model;

        AppConstants.currentBalance.value =
            model.userData?.remainingBalance.toString() ?? '0';

        final int? parentId = model.userData?.parentId;
        debugPrint('PARENT ID => $parentId');
        if (parentId != null && parentId > 0) {
          await getFamilyOwner(ownerId: parentId.toString());
        }

        await getFamilyMember();
      } else {
        SnackbarHelper.showError(data['message'] ?? "Error loading user");
      }
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e);
    } catch (_) {
      SnackbarHelper.showError('unexpected_error'.tr);
    } finally {
      isUserLoading.value = false;
    }
  }

  // Future<void> getUserData() async {
  //   try {
  //     isUserLoading.value = true;
  //     final headers = await AppConstants.getAuthHeaders();
  //     final data = await api.get(ApiUrls.getProfileUrl, headers: headers);

  //     if (data['success'] == true) {
  //       final model = UserModel.fromJson(data);
  //       AppConstants.currentUser.value = model;
  //       AppConstants.currentBalance.value = model.userData!.remainingBalance
  //           .toString();

  //       getFamilyMember();
  //       if (model.userData!.parentId != null) {
  //         await getFamilyOwner(ownerId: model.userData!.parentId!);
  //       }
  //     } else {
  //       SnackbarHelper.showError(data['message'] ?? "Error loading user");
  //     }
  //   } on ApiException catch (e) {
  //     SnackbarHelper.showError(e.message);
  //   } catch (e) {
  //     SnackbarHelper.showError("An unexpected error occurred");
  //   } finally {
  //     isUserLoading.value = false;
  //   }
  // }

  Future<void> getFamilyOwner({required String ownerId}) async {
    try {
      isOwnerLoading.value = true;
      final headers = await AppConstants.getAuthHeaders();
      final data = await api.get(
        ApiUrls.getProfileUrl,
        headers: headers,
        queryParameters: {"customer_id": ownerId},
      );

      if (data['success'] == true) {
        final model = UserModel.fromJson(data);
        AppConstants.familyOwner.value = model;
      } else {
        SnackbarHelper.showError(data['message'] ?? "Error loading owner");
      }
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e);
    } catch (e) {
      SnackbarHelper.showError('unexpected_error'.tr);
    } finally {
      isOwnerLoading.value = false;
    }
  }

  Future<void> getFamilyMember() async {
    familyError.value = null;
    try {
      isFamilyLoading.value = true;
      int? customerId = AppConstants.currentUser.value?.userData?.parentId;
      final headers = await AppConstants.getAuthHeaders();

      final params = <String, dynamic>{};
      if (customerId != null) {
        params['customer_id'] = customerId.toString();
      }

      final data = await api.get(
        ApiUrls.getFamilyMemberUrl,
        headers: headers,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (data['success'] == true) {
        final model = FamilyMemberModel.fromJson(data);
        AppConstants.familyMembers.value = model;
      } else {
        final msg = data['message']?.toString() ?? 'error_loading_family'.tr;
        familyError.value = msg;
        SnackbarHelper.showError(
          ErrorMessageHelper.toUserMessage(
            ApiException(message: msg, data: null),
            fallbackKey: 'error_loading_family',
          ),
        );
      }
    } on ApiException catch (e) {
      familyError.value = ErrorMessageHelper.toUserMessage(
        e,
        fallbackKey: 'error_loading_family',
      );
      SnackbarHelper.showApiError(e, fallbackKey: 'error_loading_family');
    } catch (e) {
      familyError.value = ErrorMessageHelper.toUserMessage(
        e,
        fallbackKey: 'error_loading_family',
      );
      SnackbarHelper.showApiError(e, fallbackKey: 'error_loading_family');
    } finally {
      isFamilyLoading.value = false;
    }
  }

  RxBool deletingAccount = false.obs;

  Future<void> deleteMyAccount() async {
    try {
      deletingAccount.value = true;
      final headers = await AppConstants.getAuthHeaders();
      final userId = AppConstants.currentUser.value?.userData?.id;

      if (userId == null) {
        SnackbarHelper.showError("User ID not found");
        return;
      }

      final body = {
        "account_id": userId,
      };

      final response = await api.post(
        ApiUrls.deleteSubAccount,
        body: body,
        headers: headers,
      );

      if (response['success'] == true) {
        SnackbarHelper.showSuccess('account_deleted'.tr);
        await AppConstants.logout();
      } else {
        SnackbarHelper.showError(
          response['message'] ?? 'unexpected_error'.tr,
        );
      }
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e);
    } catch (e) {
      SnackbarHelper.showApiError(e);
    } finally {
      deletingAccount.value = false;
    }
  }

  Future<void> deleteFamilyMember({
    required int accountId,
    required int parentCustomerId,
  }) async {
    try {
      deletingMemberId.value = accountId;

      final headers = await AppConstants.getAuthHeaders();

      final data = await api.post(
        ApiUrls.deleteSubAccount,
        headers: headers,
        body: {"account_id": accountId, "parent_customer_id": parentCustomerId},
      );

      if (data['success'] == true) {
        SnackbarHelper.showSuccess('member_deleted'.tr);
        await getFamilyMember();
      } else {
        SnackbarHelper.showError('failed_to_delete_member'.tr);
      }
    } catch (e) {
      SnackbarHelper.showApiError(e);
    } finally {
      deletingMemberId.value = -1;
    }
  }

  /// TODO(PLAYSTORE_SS): remove after Play Store screenshots.
  UserSalesModel _dummyRecentOrders() {
    final now = DateTime.now();
    String d(int daysAgo) =>
        now.subtract(Duration(days: daysAgo)).toIso8601String().split('T').first;

    return UserSalesModel(
      success: true,
      message: Message(
        data: [
          Data(
            id: 9001,
            referenceCode: 'ORD-10428',
            date: d(0),
            total: '86.50',
            paid: '86.50',
            due: '0.00',
            status: 'Completed',
            items: [
              Items(
                name: 'Chicken Shawarma Meal',
                quantity: 2,
                unit: 'pcs',
                price: '28.00',
                total: '56.00',
              ),
              Items(
                name: 'Fresh Orange Juice',
                quantity: 2,
                unit: 'pcs',
                price: '15.25',
                total: '30.50',
              ),
            ],
          ),
          Data(
            id: 9002,
            referenceCode: 'ORD-10391',
            date: d(1),
            total: '124.00',
            paid: '124.00',
            due: '0.00',
            status: 'Completed',
            items: [
              Items(
                name: 'Family Combo Platter',
                quantity: 1,
                unit: 'pcs',
                price: '99.00',
                total: '99.00',
              ),
              Items(
                name: 'Soft Drink',
                quantity: 2,
                unit: 'pcs',
                price: '12.50',
                total: '25.00',
              ),
            ],
          ),
          Data(
            id: 9003,
            referenceCode: 'ORD-10355',
            date: d(3),
            total: '45.75',
            paid: '45.75',
            due: '0.00',
            status: 'Completed',
            items: [
              Items(
                name: 'Grilled Chicken Sandwich',
                quantity: 1,
                unit: 'pcs',
                price: '32.00',
                total: '32.00',
              ),
              Items(
                name: 'French Fries',
                quantity: 1,
                unit: 'pcs',
                price: '13.75',
                total: '13.75',
              ),
            ],
          ),
          Data(
            id: 9004,
            referenceCode: 'ORD-10288',
            date: d(5),
            total: '67.00',
            paid: '0.00',
            due: '67.00',
            status: 'Completed',
            items: [
              Items(
                name: 'Beef Burger Deluxe',
                quantity: 2,
                unit: 'pcs',
                price: '33.50',
                total: '67.00',
              ),
            ],
          ),
        ],
        pagination: Pagination(
          currentPage: 1,
          lastPage: 1,
          perPage: 10,
          total: 4,
        ),
      ),
    );
  }

  Future<void> getCurrentBalance() async {
    try {
      final headers = await AppConstants.getAuthHeaders();

      final data = await api.get(ApiUrls.walletBalanceUrl, headers: headers);

      if (data['success'] == true) {
        AppConstants.currentBalance.value = data['message']['current_balance']
            .toString();
        // AppConstants.currentBalance.value = "20";
        AppConstants.currentBalance.refresh();
      } else {
        // SnackbarHelper.showError(data['message'] ?? "Error loading balance");
      }
    } on ApiException catch (_) {
      // SnackbarHelper.showError(e.message);
    } catch (_) {
      // SnackbarHelper.showError("An unexpected error occurred");
    } finally {}
  }
}
