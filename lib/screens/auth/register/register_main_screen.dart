import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/constants/app_colors.dart';
import 'package:pos_v2/controllers/register_controller.dart';
import 'package:pos_v2/screens/auth/register/personal_info_step.dart';
import 'package:pos_v2/screens/auth/register/profile_picture_step.dart';
import 'package:pos_v2/screens/auth/register/store_selection_step.dart';

import '../../../constants/app_constants.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/services/analytics_services.dart';
import '../../../utils/snakbar_helper.dart';
import '../widget/success_dialoug.dart';

class RegisterScreen extends StatefulWidget {
  final bool isFamilyMember;

  const RegisterScreen({super.key, required this.isFamilyMember});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController controller = Get.put(RegisterController());
  final ScrollController _scrollController = ScrollController();

  final _personalFormKey = GlobalKey<FormState>();

  late List<Widget> steps;
  late List<EasyStep> stepIndicators;

  @override
  void initState() {
    super.initState();
    controller.isFamilyMember = widget.isFamilyMember;
    controller.setStep(0);
    controller.reorderStoresForParent();

    steps = [
      StoreSelectionStep(controller: controller),
      Form(
        key: _personalFormKey,
        child: PersonalInfoStep(
          controller: controller,
          formKey: _personalFormKey,
        ),
      ),
      ProfilePictureStep(controller: controller),
    ];

    stepIndicators = [
      EasyStep(title: 'store'.tr, icon: const Icon(Icons.store)),
      EasyStep(title: 'personal'.tr, icon: const Icon(Icons.person)),
      EasyStep(title: 'profile_picture'.tr, icon: const Icon(Icons.photo)),
    ];
  }

  void _nextStep() {
    bool isValid = false;

    switch (controller.currentStep) {
      case 0:
        isValid = controller.selectedTenantId.value.isNotEmpty;
        if (!isValid) {
          SnackbarHelper.showError("select_store_error".tr);
          return;
        }
        AnalyticsService.logScreen(screenName: 'PersonalInformation');
        controller.nextStep();
        _scrollToTop();
        return;
      case 1:
        isValid = _personalFormKey.currentState?.validate() ?? false;
        if (!isValid) return;
        if (widget.isFamilyMember) {
          AnalyticsService.logScreen(screenName: 'AddProfilePicture');
          _addMember();
        } else {
          _submitForm();
        }
        return;
      case 2:
        isValid = controller.selectedImagePath.value.isNotEmpty;
        if (!isValid) {
          SnackbarHelper.showError("select_image_error".tr);
          return;
        }
        AnalyticsService.logScreen(screenName: 'RegistrationSuccess');
        controller.uploadUserProfileImage(
          isFamilyMember: widget.isFamilyMember,
        );
        return;
    }
  }

  void _previousStep() {
    if (controller.currentStep > 0) controller.previousStep();
  }

  Future<void> _submitForm() async {
    final isSuccess = await controller.registerUser();
    if (isSuccess) showSuccessDialog();
  }

  Future<void> _addMember() async {
    final isSuccess = await controller.addFamilyMember();
    if (isSuccess) {
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().getFamilyMember();
      }
      showSuccessDialog();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void showSuccessDialog() {
    final bool isFamily = widget.isFamilyMember;

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: SuccessDialog(
          title: isFamily ? "member_added".tr : "account_created".tr,
          message: isFamily
              ? "family_member_added_msg".tr
              : "account_created_msg".tr,
          animation: 'assets/lottie/success.json',
          btnText: isFamily ? "done".tr : "continue".tr,
          onDone: () {
            controller.nextStep();
            _scrollToTop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isFamilyMember
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                "add_member".tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: EasyStepper(
                  activeStep: controller.currentStep,
                  alignment: Alignment.center,
                  fitWidth: false,
                  lineStyle: LineStyle(
                    lineLength: 50,
                    lineSpace: 4,
                    lineType: LineType.dotted,
                    finishedLineColor: Colors.blueAccent,
                    unreachedLineColor: Colors.grey,
                    activeLineColor: Colors.grey,
                  ),
                  stepRadius: 20,
                  showLoadingAnimation: false,
                  stepShape: StepShape.circle,
                  titlesAreLargerThanSteps: true,
                  showStepBorder: true,
                  unreachedStepIconColor: Colors.grey.shade300,
                  activeStepIconColor: Colors.blue,
                  finishedStepIconColor: Colors.white,
                  finishedStepBackgroundColor: Colors.blue,
                  steps: stepIndicators,
                  onStepReached: (index) {
                    if (index < controller.currentStep) {
                      controller.setStep(index);
                    }
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: IndexedStack(
                    index: controller.currentStep,
                    children: steps,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(() => _buildBottomBar()),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            controller.currentStep > 0
                ? TextButton(onPressed: _previousStep, child: Text('back'.tr))
                : const SizedBox(),
            controller.creatingUser.isTrue || controller.uploadingImage.isTrue
                ? const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      controller.currentStep == steps.length - 1
                          ? "upload".tr
                          : controller.currentStep == 1
                              ? (widget.isFamilyMember
                                  ? "add_member".tr
                                  : "register".tr)
                              : "next".tr,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
