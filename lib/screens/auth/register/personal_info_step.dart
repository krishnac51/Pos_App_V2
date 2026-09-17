import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos_v2/controllers/register_controller.dart';

class PersonalInfoStep extends StatelessWidget {
  final RegisterController controller;
  final GlobalKey<FormState> formKey;

  const PersonalInfoStep({
    super.key,
    required this.controller,
    required this.formKey,
  });

  bool get _isChildRegistration => controller.isFamilyMember;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.dob.value ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      controller.dob.value = picked;
      controller.dobController.text = controller.formattedDob;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        _buildTextField(
          label: 'name'.tr,
          icon: Icons.person,
          controller: controller.nameController,
          validator: (v) => controller.validateRequired(v, 'name'),
        ),

        if (_isChildRegistration) ...[
          const SizedBox(height: 20),
          _buildTextField(
            label: 'username'.tr,
            icon: Icons.account_circle,
            controller: controller.usernameController,
            validator: (v) => controller.validateRequired(v, 'username'),
          ),
        ],

        const SizedBox(height: 20),
        _buildTextField(
          label: 'email'.tr,
          icon: Icons.email,
          controller: controller.emailController,
          validator: _isChildRegistration
              ? controller.validateOptionalEmail
              : controller.validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 20),
        _buildTextField(
          label: 'phone_number'.tr,
          icon: Icons.phone,
          controller: controller.phoneController,
          readOnly: !_isChildRegistration,
          suffixIcon: _isChildRegistration
              ? null
              : const Icon(Icons.lock_outline, size: 20),
          validator: _isChildRegistration
              ? null
              : (v) => controller.validateRequired(v, 'phone_number'),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
        ),

        if (_isChildRegistration) ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: controller.dobController,
            readOnly: true,
            onTap: () => _selectDate(context),
            decoration: _inputDecoration(
              'date_of_birth'.tr,
              Icons.calendar_today,
            ),
          ),
        ],

        if (!_isChildRegistration) ...[
          const SizedBox(height: 20),
          _buildTextField(
            label: 'address'.tr,
            icon: Icons.home,
            controller: controller.addressController,
            validator: (v) => controller.validateRequired(v, 'address'),
          ),
        ],

        const SizedBox(height: 20),
        _buildTextField(
          label: 'allergies'.tr,
          icon: Icons.health_and_safety_outlined,
          controller: controller.allergiesController,
          validator: null,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(250)],
        ),

        if (_isChildRegistration) ...[
          const SizedBox(height: 20),
          Obx(
            () => TextFormField(
              controller: controller.passwordController,
              obscureText: !controller.showPassword.value,
              validator: controller.validatePassword,
              decoration: _inputDecoration('password'.tr, Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.showPassword.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    controller.showPassword.toggle();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => TextFormField(
              obscureText: !controller.showConfirmPassword.value,
              decoration:
                  _inputDecoration(
                    'confirm_password'.tr,
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.showConfirmPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        controller.showConfirmPassword.toggle();
                      },
                    ),
                  ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'confirm_password'.tr;
                }
                if (value != controller.passwordController.text) {
                  return 'password_mismatch'.tr;
                }
                return null;
              },
            ),
          ),
        ],

        if (_isChildRegistration) ...[
          const SizedBox(height: 20),
          Text(
            'password_hint'.tr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: _inputDecoration(
        label,
        icon,
      ).copyWith(suffixIcon: suffixIcon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon),
    );
  }
}
