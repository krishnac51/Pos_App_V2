// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:pos_v2/controllers/edit_profile_controller.dart';
import 'package:pos_v2/controllers/home_controller.dart';
import 'package:pos_v2/widgets/app_error_widget.dart';
import 'package:pos_v2/widgets/app_screen_wrapper.dart';

import '../../core/services/analytics_services.dart';
import '../../models/family_member_model.dart';

class EditProfileScreen extends StatefulWidget {
  final Accounts? member; // 👈 optional
  const EditProfileScreen({super.key, this.member});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  EditProfileController controller = Get.put(EditProfileController());
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _govIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreen(screenName: 'EditProfile');
    if (widget.member != null) {
      final m = widget.member!;
      _nameController.text = m.name ?? "";
      _emailController.text = m.email ?? "";
      _phoneController.text = m.phone ?? "";
      _dobController.text = m.dob ?? "";
      _countryController.text = m.country ?? "";
      _cityController.text = m.city ?? "";
      _addressController.text = "";
      _usernameController.text = m.username ?? "";
      _addressController.text = m.address ?? "";
      _allergiesController.text = m.allergies ?? "";
      _govIdController.text = m.govId ?? "";
    } else {
      final user = AppConstants.currentUser.value?.userData;
      _nameController.text = user?.name ?? "";
      _emailController.text = user?.email ?? "";
      _phoneController.text = user?.phone ?? "";
      _dobController.text = user?.dob ?? "";
      _countryController.text = user?.country ?? "";
      _cityController.text = user?.city ?? "";
      _addressController.text = user?.address ?? "";
      _allergiesController.text = user?.allergies ?? "";
      _usernameController.text = user?.username ?? "";
      _govIdController.text = user?.govId ?? "";
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.member != null) {
      controller.updateFamilyMember(
        memberId: widget.member!.id!.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        govId: _govIdController.text,
        country: _countryController.text,
        city: _cityController.text,
        dob: _dobController.text,
        address: _addressController.text,
        allergies: _allergiesController.text.trim(),
      );
    } else {
      controller.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        govId: _govIdController.text,
        country: _countryController.text,
        city: _cityController.text,
        address: _addressController.text,
        dob: _dobController.text,
        allergies: _allergiesController.text.trim(),
      );
    }
  }

  String? _getProfileImage() {
    if (widget.member != null) {
      final member = widget.member!;
      if (member.media != null && member.media!.isNotEmpty) {
        final media = member.media!.firstWhere(
          (m) => m.collectionName == 'profile' || m.collectionName == 'avatar',
          orElse: () => member.media!.first,
        );
        return media.originalUrl ?? media.previewUrl;
      }

      if (member.imageUrl?.imageUrls != null &&
          member.imageUrl!.imageUrls!.isNotEmpty) {
        return member.imageUrl!.imageUrls!.first;
      }
      return null;
    }

    final user = AppConstants.currentUser.value?.userData;
    if (user?.imageUrl?.imageUrls != null &&
        user!.imageUrl!.imageUrls!.isNotEmpty) {
      return user.imageUrl!.imageUrls!.first;
    }

    return null;
  }

  Widget _profileImageUI(String? image) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: image != null && image.isNotEmpty
              ? NetworkImage(image)
              : null,
          child: image == null || image.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              controller.showImagePickerSheet(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (widget.member != null) {
      final image = _getProfileImage();
      return _profileImageUI(image);
    }

    return Obx(() {
      final image = _getProfileImage();
      return _profileImageUI(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.member == null &&
        AppConstants.currentUser.value?.userData == null) {
      return AppScreenWrapper(
        title: 'edit_profile'.tr,
        child: AppErrorWidget(
          message: 'error_loading_profile'.tr,
          onRetry: () async {
            if (Get.isRegistered<HomeController>()) {
              await Get.find<HomeController>().getUserData();
              setState(() {});
            }
          },
        ),
      );
    }
    return AppScreenWrapper(
      title: 'edit_profile'.tr,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Center(child: _buildProfileImage())),

              const SizedBox(height: 32),

              _buildSectionTitle('personal'.tr),
              const SizedBox(height: 12),
              _buildTextField(_nameController, 'name'.tr, Icons.person),
              const SizedBox(height: 16),
              _buildTextField(
                _emailController,
                'email'.tr,
                Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: widget.member != null
                    ? _optionalEmailValidator
                    : _emailValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _usernameController,
                'user_name'.tr,
                Icons.person,
                readOnly: true,
                lockedField: true,
                validator: null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _govIdController,
                'government_id'.tr,
                Icons.numbers,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _govIdValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _phoneController,
                'phone_number'.tr,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _dobController,
                'date_of_birth'.tr,
                Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _allergiesController,
                'allergies'.tr,
                Icons.health_and_safety_outlined,
                maxLines: 3,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(250),
                ],
                validator: (_) => null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('location'.tr),
              const SizedBox(height: 12),
              _buildTextField(
                _countryController,
                'country'.tr,
                Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildTextField(_cityController, 'city'.tr, Icons.location_city),
              // if (widget.member == null) ...[
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'address'.tr, Icons.home),
              // ],
              const SizedBox(height: 24),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return controller.updatingProfile.isTrue
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.blue),
                        )
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'save_changes'.tr,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 80, 80, 80),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    bool lockedField = false,
    bool obscureText = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final decoration = lockedField
        ? _lockedInputDecoration(context, label, icon)
        : _inputDecoration(label, icon);

    Widget field = TextFormField(
      controller: controller,
      readOnly: lockedField ? true : readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onTap,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      canRequestFocus: !lockedField,
      enableInteractiveSelection: !lockedField,
      showCursor: !lockedField,
      mouseCursor:
          lockedField ? SystemMouseCursors.basic : null,
      contextMenuBuilder: lockedField
          ? (context, editableTextState) => const SizedBox.shrink()
          : null,
      style: lockedField
          ? TextStyle(color: Colors.grey.shade800, fontSize: 16)
          : null,
      decoration: decoration,
      validator:
          validator ?? (v) => v?.trim().isEmpty ?? true ? 'required'.tr : null,
    );

    if (lockedField) {
      field = Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: field,
      );
    }

    return field;
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
    );
  }

  InputDecoration _lockedInputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final greyFill = Colors.grey.shade200;
    final borderColor = Colors.grey.shade400;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      disabledBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: greyFill,
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'enter_email'.tr;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
      return 'invalid_email'.tr;
    return null;
  }

  String? _optionalEmailValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
      return 'invalid_email'.tr;
    return null;
  }

  String? _govIdValidator(String? value) {
    if (value == null || value.isEmpty) return 'gov_id_required'.tr;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'gov_id_numbers_only'.tr;
    if (value.length != 10) return 'gov_id_10_digits'.tr;
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 6) return 'password_min'.tr;
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
