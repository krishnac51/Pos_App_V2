import 'package:pos_v2/constants/app_constants.dart';

String? resolveOttuCheckoutUrl({
  required String sessionId,
  String? checkoutPageUrl,
  String? checkoutUrl,
}) {
  final pageUrl = checkoutPageUrl?.trim();
  if (pageUrl != null && pageUrl.isNotEmpty) return pageUrl;

  final url = checkoutUrl?.trim();
  if (url != null && url.isNotEmpty) return url;

  final base = AppConstants.paymentBaseUrl.trim();
  if (base.isNotEmpty) {
    final normalized = base.endsWith('/') ? base : '$base/';
    return '${normalized}checkout/$sessionId/';
  }

  final merchant = AppConstants.ottuMerchantId.trim();
  if (merchant.isNotEmpty) {
    return 'https://$merchant/checkout/$sessionId/';
  }

  return null;
}
