import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:pos_v2/constants/enums.dart';
import 'package:pos_v2/controllers/home_controller.dart';
import 'package:pos_v2/controllers/wallet_controller.dart';
import 'package:pos_v2/models/family_member_model.dart' show Accounts;
import 'package:pos_v2/screens/family_member/max_amount_filed.dart';
import 'package:pos_v2/screens/sales/sales_detail.dart';
import 'package:pos_v2/widgets/order_tile.dart';
import 'package:pos_v2/widgets/wallet_card.dart';
import 'package:pos_v2/widgets/wallet_transaction_tile.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_constants.dart';
import '../../utils/snakbar_helper.dart' show SnackbarHelper;
import '../../widgets/app_screen_wrapper.dart';
import '../auth/edit_profile_screen.dart';

class FamilyMemberDetailScreen extends StatefulWidget {
  final Accounts member;
  const FamilyMemberDetailScreen({super.key, required this.member});

  @override
  State<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WalletController walletController;
  late HomeController homeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Ensure fresh instances
    Get.delete<WalletController>(force: true);
    Get.delete<HomeController>(force: true);

    walletController = Get.put(WalletController());
    homeController = Get.put(HomeController());

    if (widget.member.id != null) {
      walletController.currentBalance.value = widget.member.remainingBalance!
          .toDouble();
      walletController.fetchCustomerTransactions(customerId: widget.member.id!);
      walletController.getChildTransactionLimit(customerId: widget.member.id!);
      homeController.getMemberSales(customerId: widget.member.id!);
    }
  }

  void _showZeroBalanceWarning({
    required String title,
    required String message,
    IconData icon = Icons.warning_amber_rounded,
    Color iconColor = Colors.orange,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: iconColor),
              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(Get.context!).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ok'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showBalanceConfirmation({
    required bool isReverse,
    required double currentBalance,
    required double amount,
    required VoidCallback onConfirm,
  }) {
    final newBalance = isReverse
        ? currentBalance + amount
        : currentBalance - amount;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isReverse ? Icons.undo : Icons.swap_horiz,
                    color: isReverse ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReverse ? 'reverse_balance'.tr : 'transfer_balance'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Info text
              Text(
                isReverse
                    ? 'reverse_balance_message'.tr
                    : 'transfer_balance_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 20),

              _receiptRow(
                'your_current_balance'.tr,
                double.parse(AppConstants.currentBalance.value),
              ),

              _receiptRow(
                isReverse ? 'amount_reversed'.tr : 'amount_transferred'.tr,
                amount,
                valueColor: isReverse ? Colors.green : Colors.red,
              ),

              const Divider(height: 24),

              _receiptRow(
                'your_new_balance'.tr,
                newBalance,
                isBold: true,
                valueColor: isReverse ? Colors.green : Colors.redAccent,
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            'cancel'.tr,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Confirm Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(); // close dialog
                        Get.back(); // close bottom sheet
                        onConfirm(); // API call
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blue,
                        ),
                        child: Center(
                          child: Text(
                            'confirm'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    double value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'SAR ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showAmountBottomSheet({
    required String title,
    required String hint,
    required String buttonLabel,
    required bool isReverse,
    required Function(double amount) onSubmit,
  }) {
    final double availableBalance = isReverse
        ? walletController
              .currentBalance
              .value // Child balance
        : AppConstants
              .currentUser
              .value!
              .userData!
              .remainingBalance; // Parent balance

    final TextEditingController amountController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const SizedBox(height: 6),

              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),
              Text(
                isReverse
                    ? 'reverse_limit'.trParams({
                        'amount': availableBalance.toStringAsFixed(2),
                      })
                    : 'transfer_limit'.trParams({
                        'amount': availableBalance.toStringAsFixed(2),
                      }),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isReverse
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 20),

              // Amount input
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  MaxAmountInputFormatter(availableBalance),
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '0.0',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Text(
                      'SAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: walletController.isTransferring.value
                      ? null
                      : () {
                          final amount = double.tryParse(
                            amountController.text.trim(),
                          );
                          if (amount == null || amount <= 0) {
                            SnackbarHelper.showError('invalid_amount'.tr);
                            return;
                          }
                          if (amount > availableBalance) {
                            SnackbarHelper.showError(
                              isReverse
                                  ? 'Amount exceeds child balance'
                                  : 'Amount exceeds your available balance',
                            );
                            return;
                          }

                          onSubmit(amount);
                          // Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: walletController.isTransferring.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          buttonLabel.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
      isScrollControlled: true,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? getProfileImageUrl() {
    if (widget.member.media != null && widget.member.media!.isNotEmpty) {
      final profileMedia = widget.member.media!.firstWhere(
        (m) => m.collectionName == 'profile' || m.collectionName == 'avatar',
        orElse: () => widget.member.media!.first,
      );
      return profileMedia.originalUrl ?? profileMedia.previewUrl;
    }
    if (widget.member.imageUrl?.imageUrls != null &&
        widget.member.imageUrl!.imageUrls!.isNotEmpty) {
      return widget.member.imageUrl!.imageUrls!.first;
    }
    return null;
  }

  String getFormattedDob() {
    if (widget.member.dob == null) return 'not_provided'.tr;
    try {
      final date = DateTime.parse(widget.member.dob!);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return widget.member.dob!;
    }
  }

  String getJoinDate() {
    if (widget.member.createdAt == null) return 'unknown'.tr;
    try {
      final date = DateTime.parse(widget.member.createdAt!);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return widget.member.createdAt!;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'on the way':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? profileImage = getProfileImageUrl();
    final isParent = AppConstants.currentUser.value?.userData?.parentId == null;

    return AppScreenWrapper(
      title: 'view_member'.tr,
      child: Column(
        children: [
          // Profile header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profileImage != null
                      ? CachedNetworkImageProvider(profileImage)
                      : null,
                  child: profileImage == null
                      ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.member.name ?? 'unnamed'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.member.username ??
                      widget.member.email ??
                      'no_username'.tr,
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => WalletCard(
                    balance: walletController.currentBalance.value,
                    showRecharge: false,
                    onRecharge: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('recharge_soon'.tr)),
                      );
                    },

                    extraContent: isParent
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.swap_horiz,
                                  label: 'transfer'.tr, // translated
                                  iconColor: Colors.white,
                                  textColor: Colors.white,
                                  onTap: () async {
                                    Get.dialog(
                                      WillPopScope(
                                        onWillPop: () async => false,
                                        child: Center(
                                          child: Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const CircularProgressIndicator(),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'loading'.tr,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      barrierDismissible: false,
                                    );
                                    try {
                                      await homeController.getCurrentBalance();
                                    } finally {
                                      if (Get.isDialogOpen == true) Get.back();
                                    }
                                    final parentBalance =
                                        double.tryParse(
                                          AppConstants.currentBalance.value,
                                        ) ??
                                        0;
                                    if (parentBalance <= 0) {
                                      _showZeroBalanceWarning(
                                        title: 'insufficient_balance'.tr,
                                        message: 'no_balance_transfer_desc'.tr,
                                      );
                                      return;
                                    }

                                    /// ✅ Open bottom sheet ONLY if balance > 0
                                    _showAmountBottomSheet(
                                      title: 'transfer_amount'.tr,
                                      hint: 'enter_amount_transfer'.tr,
                                      buttonLabel: 'transfer'.tr,
                                      isReverse: false,
                                      onSubmit: (amount) {
                                        showBalanceConfirmation(
                                          isReverse: false,
                                          currentBalance: parentBalance,
                                          amount: amount,
                                          onConfirm: () {
                                            walletController
                                                .transferAmountToMember(
                                                  toCustomerId:
                                                      widget.member.id!,
                                                  amount: amount,
                                                );
                                          },
                                        );
                                      },
                                    );
                                  },

                                  // onTap: ()

                                  // => _showAmountBottomSheet(
                                  //   title: 'transfer_amount'.tr,
                                  //   hint: 'enter_amount_transfer'.tr,
                                  //   buttonLabel: 'transfer'.tr,
                                  //   isReverse: false,
                                  //   onSubmit: (amount) {
                                  //     showBalanceConfirmation(
                                  //       isReverse: false,
                                  //       currentBalance: double.parse(
                                  //         AppConstants.currentBalance.value,
                                  //       ),
                                  //       amount: amount,
                                  //       onConfirm: () {
                                  //         walletController
                                  //             .transferAmountToMember(
                                  //               toCustomerId: widget.member.id!,
                                  //               amount: amount,
                                  //             );
                                  //       },
                                  //     );
                                  //   },
                                  // ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.swap_horiz,
                                  label: 'reverse'.tr, // translated
                                  iconColor: Colors.white,
                                  textColor: Colors.white,
                                  onTap: () {
                                    final childBalance =
                                        walletController.currentBalance.value;
                                    if (childBalance <= 0) {
                                      _showZeroBalanceWarning(
                                        title: 'no_balance_to_reverse'.tr,
                                        message: 'no_balance_reverse_desc'.tr,
                                      );
                                      return;
                                    }

                                    /// ✅ Open bottom sheet ONLY if balance > 0
                                    _showAmountBottomSheet(
                                      title: 'reverse_amount'.tr,
                                      hint: 'enter_amount_reverse'.tr,
                                      buttonLabel: 'reverse'.tr,
                                      isReverse: true,
                                      onSubmit: (amount) {
                                        showBalanceConfirmation(
                                          isReverse: true,
                                          currentBalance:
                                              double.tryParse(
                                                AppConstants
                                                    .currentBalance
                                                    .value,
                                              ) ??
                                              0,
                                          amount: amount,
                                          onConfirm: () {
                                            walletController
                                                .reverseTransferToParent(
                                                  fromCustomerId:
                                                      widget.member.id!,
                                                  amount: amount,
                                                );
                                          },
                                        );
                                      },
                                    );
                                  },

                                  // onTap: () => _showAmountBottomSheet(
                                  //   title: 'reverse_amount'.tr,
                                  //   hint: 'enter_amount_reverse'.tr,
                                  //   buttonLabel: 'reverse'.tr,
                                  //   isReverse: true,
                                  //   onSubmit: (amount) {
                                  //     showBalanceConfirmation(
                                  //       isReverse: true,
                                  //       currentBalance: double.parse(
                                  //         AppConstants.currentBalance.value,
                                  //       ),
                                  //       amount: amount,
                                  //       onConfirm: () {
                                  //         walletController
                                  //             .reverseTransferToParent(
                                  //               fromCustomerId:
                                  //                   widget.member.id!,
                                  //               amount: amount,
                                  //             );
                                  //       },
                                  //     );
                                  //   },
                                  // ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                // Obx(
                //   () => WalletCard(
                //     balance: walletController.currentBalance.value,
                //     showRecharge: false,
                //     onRecharge: () {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(content: Text('recharge_soon'.tr)),
                //       );
                //     },
                //   ),
                // ),
                const SizedBox(height: 16),
                if (isParent)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => Get.to(
                              () => EditProfileScreen(member: widget.member),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            label: Text(
                              'edit_profile'.tr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _showChildLimitBottomSheet(),
                            icon: const Icon(Icons.tune, size: 20),
                            label: Text(
                              'set_limit'.tr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!isParent)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(
                        () => EditProfileScreen(member: widget.member),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: Text(
                        'edit_profile'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(text: 'personal_info'.tr),
                Tab(text: 'transactions'.tr),
                Tab(text: 'sales'.tr),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildTransactionsTab(),
                _buildSalesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChildLimitBottomSheet() {
    if (!walletController.isChildLimitLoading.value &&
        walletController.childMaxPerTransaction.value > 0) {
      walletController.tempChildMaxPerTxn.value = walletController
          .childMaxPerTransaction
          .value
          .clamp(10.0, 200.0);
      walletController.tempChildMaxDailyTxn.value = walletController
          .childMaxDailyTransaction
          .value
          .toDouble()
          .clamp(10.0, 200.0);
    } else if (!walletController.isChildLimitLoading.value) {
      walletController.tempChildMaxPerTxn.value = 10.0;
      walletController.tempChildMaxDailyTxn.value = 10.0;
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(() {
          if (walletController.isChildLimitLoading.value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'set_child_limit'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'set_child_limit_desc'.tr,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'set_child_limit'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'set_child_limit_desc'.tr,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                'max_per_transaction_label'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SAR ${walletController.tempChildMaxPerTxn.value.toInt()}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                min: 10,
                max: 200,
                divisions: 190,
                value: walletController.tempChildMaxPerTxn.value.clamp(
                  10.0,
                  200.0,
                ),
                onChanged: (v) => walletController.tempChildMaxPerTxn.value = v,
              ),
              const SizedBox(height: 16),
              Text(
                'max_daily_transaction_label'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${walletController.tempChildMaxDailyTxn.value.toInt()}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                min: 10,
                max: 200,
                divisions: 190,
                value: walletController.tempChildMaxDailyTxn.value.clamp(
                  10.0,
                  200.0,
                ),
                onChanged: (v) =>
                    walletController.tempChildMaxDailyTxn.value = v,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    walletController.updateChildTransactionLimit(
                      customerId: widget.member.id!,
                      maxPerTransaction: walletController
                          .tempChildMaxPerTxn
                          .value
                          .toInt()
                          .toString(),
                      maxDailyTransaction: walletController
                          .tempChildMaxDailyTxn
                          .value
                          .toInt()
                          .toString(),
                    );
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
                    'confirm'.tr,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      isScrollControlled: true,
    );
  }

  /// Single reusable action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor, // optional icon color
    Color? textColor, // optional text color
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: iconColor ?? Colors.black, // default color if not provided
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black, // default color if not provided
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: textColor ?? Colors.black,
          ), // optional border color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildPersonalInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        Text(
          'personal_information'.tr,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildInfoRow(
          Icons.phone,
          'phone'.tr,
          widget.member.phone ?? 'not_provided'.tr,
        ),
        if (widget.member.email != null &&
            widget.member.email!.trim().isNotEmpty)
          _buildInfoRow(Icons.email, 'email'.tr, widget.member.email!),
        _buildInfoRow(Icons.cake, 'date_of_birth'.tr, getFormattedDob()),
        _buildInfoRow(
          Icons.health_and_safety_outlined,
          'allergies'.tr,
          (widget.member.allergies ?? '').trim().isEmpty
              ? 'not_provided'.tr
              : widget.member.allergies!,
        ),
        _buildInfoRow(
          Icons.location_city,
          'location'.tr,
          "${widget.member.city ?? ''}${widget.member.city != null ? ', ' : ''}${widget.member.country ?? ''}"
                  .trim()
                  .isEmpty
              ? 'not_provided'.tr
              : "${widget.member.city ?? ''}${widget.member.city != null ? ', ' : ''}${widget.member.country ?? ''}",
        ),
        _buildInfoRow(
          Icons.home,
          'address'.tr,
          (widget.member.address ?? '').trim().isEmpty
              ? 'not_provided'.tr
              : widget.member.address!,
        ),
        _buildInfoRow(
          Icons.credit_card,
          'gov_id'.tr,
          widget.member.govId ?? 'not_provided'.tr,
        ),
        _buildInfoRow(Icons.calendar_today, 'member_since'.tr, getJoinDate()),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return Obx(() {
      if (walletController.isCustomerLoading.value &&
          walletController.customerTransactions.isEmpty) {
        return _buildShimmerList();
      }
      if (walletController.customerTransactions.isEmpty) {
        return _buildEmptyState(
          'no_transaction_yet'.tr,
          "assets/lottie/empty.json",
        );
      }
      return RefreshIndicator(
        onRefresh: () =>
            walletController.refreshCustomerTransactions(widget.member.id!),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount:
              walletController.customerTransactions.length +
              (walletController.customerHasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == walletController.customerTransactions.length) {
              walletController.loadNextCustomerPage(widget.member.id!);
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final txn = walletController.customerTransactions[index];
            final type =
                (txn.transactionType?.toLowerCase() ?? 'debit') == 'credit'
                ? TransactionType.credit
                : TransactionType.debit;
            final color = type == TransactionType.credit
                ? Colors.green
                : Colors.redAccent;
            final formattedAmount = type == TransactionType.credit
                ? '+SAR ${(txn.amount ?? 0).toStringAsFixed(2)}'
                : '-SAR ${(txn.amount ?? 0).toStringAsFixed(2)}';
            final date = txn.createdAt?.split(' ').first ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WalletTransactionTile(
                transactionId: txn.transactionId ?? '#TRX${txn.id}',
                transactionType: type,
                statusColor: color,
                balance: txn.balance.toString(),
                date: date,
                amount: formattedAmount,
                index: index,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSalesTab() {
    return Obx(() {
      if (homeController.isMemberSaleLoading.value &&
          homeController.memberSales.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final salesData = homeController.memberSales.value?.message?.data ?? [];
      if (salesData.isEmpty) {
        return _buildEmptyState(
          'no_orders_yet'.tr,
          "assets/lottie/no_data.json",
        );
      }

      return RefreshIndicator(
        onRefresh: () =>
            homeController.getMemberSales(customerId: widget.member.id!),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount:
              salesData.length + (homeController.memberHasMorePages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == salesData.length) {
              homeController.loadNextMemberPage(widget.member.id!);
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final order = salesData[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Get.to(() => OrderDetailScreen(order: order)),
                child: OrderTile(
                  orderId: order.referenceCode ?? '',
                  status: order.status ?? '',
                  statusColor: _getStatusColor(order.status),
                  date: order.date != null
                      ? DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(order.date!))
                      : 'unknown'.tr,
                  amount: "SAR ${order.total ?? '0.00'}",
                  delayAnimation: 100 * (index + 1),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, String lottiePath) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(lottiePath, width: 140, height: 140, repeat: true),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
