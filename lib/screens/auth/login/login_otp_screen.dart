import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:pos_v2/constants/app_colors.dart';
import 'package:pos_v2/controllers/login_controller.dart';
import 'package:pos_v2/screens/auth/register/register_main_screen.dart';

import '../../../core/services/analytics_services.dart';
import '../../../utils/snakbar_helper.dart';

/// OTP presentation for phone login.
///
class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String requestId;

  const LoginOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.requestId,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen>
    with TickerProviderStateMixin {
  static const _resendDuration = 30;
  static const _otpLength = 4;

  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginController _loginController = Get.find<LoginController>();

  late final AnimationController _entryController;
  late final AnimationController _glowController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  Timer? _resendTimer;
  int _secondsRemaining = _resendDuration;
  bool _canResend = false;
  bool _hasCompleteOtp = false;
  bool _isResending = false;
  bool _isVerifying = false;
  late String _requestId;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreen(screenName: 'LoginPhoneOTP');
    _requestId = widget.requestId;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _entryController.forward();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _entryController.dispose();
    _glowController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _secondsRemaining = _resendDuration;
    _canResend = false;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isResending = true);
    final challenge = await _loginController.resendPhoneOtp(widget.phoneNumber);

    if (!mounted) return;
    if (challenge != null) {
      _requestId = challenge.requestId;
      _otpController.clear();
      setState(() => _hasCompleteOtp = false);
      _startResendTimer();
      if (challenge.apiMessage != null &&
          challenge.apiMessage!.trim().isNotEmpty) {
        SnackbarHelper.showSuccess(challenge.apiMessage!.trim());
      }
    }
    setState(() => _isResending = false);
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'enter_otp'.tr;
    if (value.length != _otpLength) return 'otp_four_digits'.tr;
    return null;
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isVerifying = true);
    final result = await _loginController.verifyPhoneOtp(
      mobile: widget.phoneNumber,
      activeKey: _otpController.text,
      requestId: _requestId,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result?.isNewUser == true) {
      Get.off(
        () => RegisterScreen(
          isFamilyMember: false,
          initialPhoneNumber: result!.mobile,
        ),
      );
    }
  }

  String _maskedPhoneNumber() {
    final phone = widget.phoneNumber.trim();
    if (phone.length <= 4) return phone;

    final prefixLength = phone.length > 7 ? 3 : 1;
    final hiddenLength = phone.length - prefixLength - 4;
    // Isolate the number as LTR so it is not reordered inside RTL text.
    return '⁦${phone.substring(0, prefixLength)}'
        '${'•' * hiddenLength}'
        '${phone.substring(phone.length - 4)}⁩';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black87,
        ),
        title: Text(
          'verify_otp'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: _buildVerificationCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _buildDecorativeCircle(
              190,
              AppColors.cardBg.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _buildDecorativeCircle(
              220,
              AppColors.primaryBlue.withValues(alpha: 0.045),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildVerificationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B2B4C),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildAnimatedIllustration(),
            const SizedBox(height: 12),
            Text(
              'otp_verification'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'enter_otp_for'.trParams({'user': _maskedPhoneNumber()}),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 26),
            _buildOtpSection(context),
            const SizedBox(height: 22),
            _buildResendSection(),
            const SizedBox(height: 26),
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIllustration() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = 0.10 + (_glowController.value * 0.08);
        return Container(
          width: 154,
          height: 154,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: glow),
                blurRadius: 28 + (_glowController.value * 8),
                spreadRadius: 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Lottie.asset(
        'assets/lottie/otp.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }

  Widget _buildOtpSection(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fieldWidth = ((screenWidth - 112) / _otpLength)
        .clamp(42.0, 56.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_otp'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        // OTP digits always fill left to right, also in Arabic.
        Directionality(
          textDirection: TextDirection.ltr,
          child: PinCodeTextField(
            appContext: context,
            length: _otpLength,
            controller: _otpController,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.disabled,
            cursorColor: AppColors.primaryBlue,
            autoDismissKeyboard: true,
            animationType: AnimationType.scale,
            enableActiveFill: true,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(13),
              fieldHeight: 54,
              fieldWidth: fieldWidth,
              activeColor: AppColors.primaryBlue,
              selectedColor: AppColors.primaryBlue,
              inactiveColor: const Color(0xFFD9E1EC),
              activeFillColor: AppColors.cardBg,
              selectedFillColor: Colors.white,
              inactiveFillColor: const Color(0xFFF9FBFD),
            ),
            onChanged: (value) {
              final isComplete = value.length == _otpLength;
              if (_hasCompleteOtp != isComplete) {
                setState(() => _hasCompleteOtp = isComplete);
              }
            },
            validator: _validateOtp,
          ),
        ),
      ],
    );
  }

  Widget _buildResendSection() {
    final progress = _secondsRemaining / _resendDuration;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: child,
        ),
      ),
      child: _canResend
          ? TextButton.icon(
              key: const ValueKey('resend'),
              onPressed: _isResending ? null : _resendOtp,
              icon: _isResending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 19),
              label: Text(
                'resend_otp'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            )
          : Row(
              key: const ValueKey('timer'),
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResendProgress(progress),
                const SizedBox(width: 9),
                Text(
                  'resend_in'.trParams({
                    'seconds': _secondsRemaining.toString(),
                  }),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResendProgress(double progress) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            const CircularProgressIndicator(
              value: 1,
              strokeWidth: 2.6,
              color: AppColors.cardBg,
            ),
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.6,
              color: AppColors.primaryBlue,
            ),
            Center(
              child: Text(
                _secondsRemaining.toString(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hasCompleteOtp
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _hasCompleteOtp && !_isVerifying ? _verifyOtp : null,
          icon: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text(
            'verify_otp'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFB8CDE2),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
