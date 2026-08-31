class InitiatePaymentModel {
  bool? success;
  Message? message;

  InitiatePaymentModel({this.success, this.message});

  InitiatePaymentModel.fromJson(Map<String, dynamic> json) {
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
