import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:pos_v2/constants/app_colors.dart';
import 'package:pos_v2/controllers/register_controller.dart';

class AccessCodeStep extends StatelessWidget {
  final RegisterController controller;

  const AccessCodeStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fieldWidth = ((MediaQuery.sizeOf(context).width - 112) / 4)
        .clamp(48.0, 62.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF4FF), Color(0xFFF7FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD6E8FF)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'create_access_code'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14253D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'create_access_code_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              const SizedBox(height: 28),
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: controller.accessCodeController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.scale,
                enableActiveFill: true,
                autoDismissKeyboard: false,
                cursorColor: AppColors.primaryBlue,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(14),
                  fieldHeight: 58,
                  fieldWidth: fieldWidth,
                  activeColor: AppColors.primaryBlue,
                  selectedColor: AppColors.primaryBlue,
                  inactiveColor: const Color(0xFFD6E2F0),
                  activeFillColor: const Color(0xFFEAF4FF),
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blueGrey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'access_code_private_hint'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
