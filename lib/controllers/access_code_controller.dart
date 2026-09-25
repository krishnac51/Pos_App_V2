import 'package:get/get.dart';
import 'package:pos_v2/constants/api_urls.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:pos_v2/core/services/api_services.dart';
import 'package:pos_v2/utils/error_message_helper.dart';
import 'package:pos_v2/utils/snakbar_helper.dart';

class AccessCodeController extends GetxController {
  final api = Get.find<ApiService>();
  final isUpdating = false.obs;

  Future<bool> updateAccessCode({
    required int userId,
    required String accessCode,
    required bool accessCodeEnable,
  }) async {
    try {
      isUpdating.value = true;
      final response = await api.post(
        ApiUrls.updateAccessCodeUrl,
        headers: await AppConstants.getAuthHeaders(),
        body: {
          'user_id': userId,
          'access_code': accessCode,
          'access_code_enable': accessCodeEnable,
        },
      );

      if (response['success'] == true) {
        SnackbarHelper.showSuccess('access_code_updated'.tr);
        return true;
      }

      SnackbarHelper.showError(
        ErrorMessageHelper.responseMessage(
          response,
          fallbackKey: 'access_code_update_failed',
        ),
      );
      return false;
    } on ApiException catch (e) {
      SnackbarHelper.showApiError(e, fallbackKey: 'access_code_update_failed');
      return false;
    } catch (_) {
      SnackbarHelper.showError('unexpected_error'.tr);
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
