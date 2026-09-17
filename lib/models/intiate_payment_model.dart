class InitiatePaymentModel {
  bool? success;
  Message? message;
  String? errorMessage;

  InitiatePaymentModel({this.success, this.message, this.errorMessage});

  InitiatePaymentModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['message'] is String) {
      errorMessage = json['message'];
      message = null;
    } else if (json['message'] != null) {
      message = Message.fromJson(json['message']);
      errorMessage = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (errorMessage != null) {
      data['message'] = errorMessage;
    } else if (message != null) {
      data['message'] = message!.toJson();
    }
    return data;
  }
}

class Message {
  String? orderNo;
  double? amount;
  String? sessionId;
  String? expiresIn;
  String? checkoutPageUrl;
  String? checkoutUrl;

  Message({
    this.orderNo,
    this.amount,
    this.sessionId,
    this.expiresIn,
    this.checkoutPageUrl,
    this.checkoutUrl,
  });

  Message.fromJson(Map<String, dynamic> json) {
    orderNo = json['order_no'];
    amount = (json['amount'] as num?)?.toDouble();
    sessionId = json['session_id'];
    expiresIn = json['expires_in'];
    checkoutPageUrl = json['checkout_page_url'];
    checkoutUrl = json['checkout_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_no'] = orderNo;
    data['amount'] = amount;
    data['session_id'] = sessionId;
    data['expires_in'] = expiresIn;
    data['checkout_page_url'] = checkoutPageUrl;
    data['checkout_url'] = checkoutUrl;
    return data;
  }
}
