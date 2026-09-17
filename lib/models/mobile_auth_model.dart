class OtpChallenge {
  final bool isNewUser;
  final String mobile;
  final String requestId;
  final bool otpSent;
  final String? apiMessage;

  const OtpChallenge({
    required this.isNewUser,
    required this.mobile,
    required this.requestId,
    required this.otpSent,
    this.apiMessage,
  });

  factory OtpChallenge.fromResponse(
    Map<String, dynamic> response, {
    required String fallbackMobile,
  }) {
    final message = response['message'];
    final payload = message is Map
        ? Map<String, dynamic>.from(message)
        : <String, dynamic>{};

    return OtpChallenge(
      isNewUser: payload['isNewUser'] == true,
      mobile: payload['mobile']?.toString() ?? fallbackMobile,
      requestId: payload['requestId']?.toString() ?? '',
      otpSent: payload['otpSent'] == true,
      apiMessage: message is String ? message : null,
    );
  }
}

class PhoneVerificationResult {
  final bool isNewUser;
  final String mobile;

  const PhoneVerificationResult({
    required this.isNewUser,
    required this.mobile,
  });
}
