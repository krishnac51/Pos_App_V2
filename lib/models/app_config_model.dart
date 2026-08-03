class AppConfig {
  bool? success;
  Message? message;

  AppConfig({this.success, this.message});

  AppConfig.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'] != null
        ? Message.fromJson(json['message'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (message != null) {
      data['message'] = message!.toJson();
    }
    return data;
  }
}

class Message {
  String? paymentBaseUrl;
  String? paymentApiKey;
  double? minRecharge;

  Message({this.paymentBaseUrl, this.paymentApiKey, this.minRecharge});

  Message.fromJson(Map<String, dynamic> json) {
    paymentBaseUrl = json['payment_base_url'];
    paymentApiKey = json['payment_api_key'];
    minRecharge = _safeDouble(json['min_recharge']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['payment_base_url'] = paymentBaseUrl;
    data['payment_api_key'] = paymentApiKey;
    data['min_recharge'] = minRecharge;
    return data;
  }

  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
