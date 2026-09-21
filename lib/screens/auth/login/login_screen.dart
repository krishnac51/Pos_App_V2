import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/constants/app_colors.dart' show AppColors;
import 'package:pos_v2/controllers/login_controller.dart';
// import 'package:pos_v2/screens/auth/frogetPassword/forget_password.dart';
import 'package:pos_v2/screens/auth/login/login_otp_screen.dart';

import '../../../core/services/analytics_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = Get.put(LoginController());
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocusNode = FocusNode();
  bool _isPhoneNumber = false;
  bool _showPasswordField = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreen(screenName: 'Login');
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  bool _containsOnlyDigits(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isNotEmpty &&
        trimmedValue.runes.every((rune) => rune >= 48 && rune <= 57);
  }

  void _handleUsernameChanged(String value) {
    final isPhoneNumber = _containsOnlyDigits(value);
    final hasText = value.trim().isNotEmpty;
    final showPasswordField = hasText && !isPhoneNumber;
    if (isPhoneNumber == _isPhoneNumber &&
        showPasswordField == _showPasswordField) {
      return;
    }

    setState(() {
      _isPhoneNumber = isPhoneNumber;
      _showPasswordField = showPasswordField;
    });

    // Do not carry a password into the phone/OTP flow, or after the
    // identifier is cleared, if the user changes the input type.
    if (!showPasswordField) {
      passwordController.clear();
      passwordFocusNode.unfocus();
    }
  }

  Future<void> _continue() async {
    final username = userNameController.text.trim();

    if (username.isEmpty) {
      controller.formKey.currentState?.validate();
      return;
    }

    if (_isPhoneNumber) {
      if (!(controller.formKey.currentState?.validate() ?? false)) return;

      FocusScope.of(context).unfocus();
      AnalyticsService.logScreen(screenName: 'LoginPhoneOTP');
      final challenge = await controller.loginWithPhone(username);
      if (challenge != null && mounted) {
        await Get.to(
          () => LoginOtpScreen(
            phoneNumber: challenge.mobile,
            requestId: challenge.requestId,
          ),
        );
      }
      return;
    }

    if (!(controller.formKey.currentState?.validate() ?? false)) return;

    await controller.login(
      username: username,
      password: passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    _buildLoginHeaderAnimation(),
                    const SizedBox(height: 12),
                    Text(
                      'welcome_back'.tr,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'sign_in_continue'.tr,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 34),
                    _buildUsernameField(),
                    _buildPasswordFieldTransition(),
                    const SizedBox(height: 28),
                    _buildContinueButton(),
                    // Forgot password is temporarily disabled.
                    // Uncomment this block when the flow is enabled again.
                    // const SizedBox(height: 12),
                    // TextButton(
                    //   onPressed: () {
                    //     AnalyticsService.logScreen(
                    //       screenName: 'ForgetPassword',
                    //     );
                    //     Get.to(() => ForgotPasswordScreen());
                    //   },
                    //   child: Text(
                    //     'forgot_password'.tr,
                    //     style: const TextStyle(color: Colors.blue),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: userNameController,
      onChanged: _handleUsernameChanged,
      textInputAction: _isPhoneNumber
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (_isPhoneNumber) {
          _continue();
        } else {
          passwordFocusNode.requestFocus();
        }
      },
      decoration: InputDecoration(
        labelText: 'login_identifier_label'.tr,
        hintText: 'login_identifier_hint'.tr,
        helperText: 'login_identifier_helper'.tr,
        helperMaxLines: 2,
        prefixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Icon(
            _isPhoneNumber ? Icons.phone_rounded : Icons.person_outline,
            key: ValueKey(_isPhoneNumber),
            color: AppColors.primaryBlue,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.text,
      validator: (value) => _isPhoneNumber
          ? controller.validatePhoneNumber(value)
          : controller.validateUserName(value),
    );
  }

  Widget _buildPasswordFieldTransition() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, -0.12),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: SlideTransition(position: slideAnimation, child: child),
          ),
        );
      },
      child: !_showPasswordField
          ? const SizedBox.shrink(key: ValueKey('phone-login'))
          : Padding(
              key: const ValueKey('username-login'),
              padding: const EdgeInsets.only(top: 18),
              child: TextFormField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _continue(),
                decoration: InputDecoration(
                  labelText: 'password'.tr,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: controller.validatePassword,
              ),
            ),
    );
  }

  Widget _buildContinueButton() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return ElevatedButton(
        onPressed: _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _isPhoneNumber ? 'continue'.tr : 'login'.tr,
            key: ValueKey(_isPhoneNumber),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  Widget _buildLoginHeaderAnimation() {
    return Align(
      child: FractionallySizedBox(
        widthFactor: 0.92,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.asset(
              'assets/images/login_ani.gif',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Arabic school and children animation',
            ),
          ),
        ),
      ),
    );
  }
}
