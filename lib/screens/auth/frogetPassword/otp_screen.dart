import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:pos_v2/controllers/auth_controller.dart';

class OtpScreen extends StatelessWidget {
  final String userName;
  OtpScreen({super.key, required this.userName});

  final AuthController controller = Get.put(AuthController());
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'verify_otp'.tr,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: otpFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Lottie.asset(
                  'assets/lottie/otp.json',
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  animate: true,
                  repeat: true,
                ),
                const SizedBox(height: 20),

                /// Title
                Text(
                  'otp_verification'.tr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                /// Subtitle
                Text(
                  'enter_otp_for'.trParams({'user': userName}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                /// OTP Field
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.disabled,
                    cursorColor: Colors.black,
                    autoDismissKeyboard: true,
                    animationType: AnimationType.fade,
                    blinkWhenObscuring: true,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 50,
                      fieldWidth: 45,
                      activeColor: Colors.blue,
                      selectedColor: Colors.blueAccent,
                      inactiveColor: Colors.grey.shade400,
                    ),
                    onChanged: (value) {},
                    validator: (v) => controller.validateOtp(v),
                  ),
                ),
                const SizedBox(height: 5),

                /// Resend OTP
                Align(
                  alignment: Alignment.bottomRight,
                  child: Obx(() {
                    return controller.enableResend.value
                        ? InkWell(
                            onTap: () {
                              controller.sendOtp(
                                userName: userName,
                                isResend: true,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'resend_otp'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            'resend_in'.trParams({
                              'seconds': controller.secondsRemaining.value
                                  .toString(),
                            }),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          );
                  }),
                ),
                const SizedBox(height: 20),

                /// New Password
                Obx(() {
                  return TextFormField(
                    controller: passwordController,
                    obscureText: !controller.showPassword.value,
                    decoration: InputDecoration(
                      labelText: 'new_password'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.showPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          controller.showPassword.value =
                              !controller.showPassword.value;
                        },
                      ),
                    ),
                    validator: controller.validatePassword,
                  );
                }),
                const SizedBox(height: 20),

                /// Confirm Password
                Obx(() {
                  return TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !controller.showConfirmPassword.value,
                    decoration: InputDecoration(
                      labelText: 'confirm_password'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.showConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          controller.showConfirmPassword.value =
                              !controller.showConfirmPassword.value;
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v != passwordController.text) {
                        return 'passwords_do_not_match'.tr;
                      }
                      return null;
                    },
                  );
                }),
                const SizedBox(height: 30),

                /// Verify OTP Button
                Obx(() {
                  return controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.blue)
                      : ElevatedButton(
                          onPressed: () async {
                            if (otpFormKey.currentState!.validate()) {
                              await controller.verifyOtp(
                                userName: userName,
                                otp: otpController.text,
                                password: passwordController.text,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'verify_otp'.tr,
                            style: const TextStyle(fontSize: 18),
                          ),
                        );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
