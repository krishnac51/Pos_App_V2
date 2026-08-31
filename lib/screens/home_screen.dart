import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:pos_v2/screens/auth/register/register_main_screen.dart';
import 'package:pos_v2/screens/family_member/family_screen.dart';
import 'package:pos_v2/screens/recharge/wallert_recharge.dart';
import 'package:pos_v2/screens/sales/sales_detail.dart';
import 'package:pos_v2/screens/wallet_screen.dart';
import 'package:pos_v2/widgets/login_wrapper.dart';

import '../constants/shimmer.dart';
import '../controllers/bottom_nav_controller.dart';
import '../controllers/home_controller.dart';
import '../core/services/analytics_services.dart';
import '../utils/snakbar_helper.dart' show SnackbarHelper;
import '../widgets/app_error_widget.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/family_card.dart';
import '../widgets/order_tile.dart';
import '../widgets/wallet_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BottomNavController navController = Get.put(
    BottomNavController(),
    permanent: true,
  );

  final HomeController controller = Get.put(HomeController(), permanent: true);

  final Map<int, Widget> _pageCache = {};

  final Map<int, Widget Function()> _pageBuilders = {
    0: () => const _HomePageContent(),
    1: () => WalletScreen(),
    2: () => FamilyScreen(),
  };

  @override
  void initState() {
    super.initState();
    if (navController.currentIndex.value >= _pageBuilders.length) {
      navController.currentIndex.value = 0;
    }
    _buildPageIfNeeded(0);
    controller.getCurrentBalance();
    ever(navController.currentIndex, (index) {
      if (index == 1) {
        _pageCache[1] = _pageBuilders[1]!();
      } else {
        _buildPageIfNeeded(index);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshTabData(index);
      });
    });
    // After payment: `changeIndex(1)` runs before `Get.offAll(HomeScreen())`, so the new
    // `HomeScreen` mounts with wallet already selected but `ever` does not fire (no change).
    // Build the active tab's page so IndexedStack is not empty.
    _ensureActiveTabPageBuilt();
  }

  void _ensureActiveTabPageBuilt() {
    final index = navController.currentIndex.value;
    if (index == 1) {
      if (!_pageCache.containsKey(1)) {
        _pageCache[1] = _pageBuilders[1]!();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshTabData(1);
        });
      }
    } else if (!_pageCache.containsKey(index)) {
      _buildPageIfNeeded(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshTabData(index);
      });
    }
  }

  void _refreshTabData(int index) {
    switch (index) {
      case 0:
        controller.getCurrentBalance();
        controller.getUserSales();
        controller.getFamilyMember();
        break;
      case 1:
        controller.getCurrentBalance();
        // WalletController.onInit already calls fetchTransactions + getTransactionLimit
        // Avoid duplicate API calls (and duplicate error toasts) on tab switch
        break;
      case 2:
        controller.getFamilyMember();
        break;
    }
  }

  void _buildPageIfNeeded(int index) {
    if (!_pageCache.containsKey(index)) {
      _pageCache[index] = _pageBuilders[index]!();
    }
  }

  void _onItemTapped(int index) {
    navController.changeIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: IndexedStack(
          index: navController.currentIndex.value,
          children: List.generate(
            _pageBuilders.length,
            (index) => _pageCache[index] ?? const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: navController.currentIndex.value,
          onTap: _onItemTapped,
        ),
      );
    });
  }
}

class _HomePageContent extends StatefulWidget {
  const _HomePageContent({super.key});

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<HomeController>();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _refreshSpinController;
  late final Worker _saleLoadingWorker;

  @override
  void initState() {
    super.initState();
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _saleLoadingWorker = ever<bool>(controller.isSaleLoading, (loading) {
      if (loading) {
        _refreshSpinController.repeat();
      } else {
        _refreshSpinController.stop();
        _refreshSpinController.reset();
      }
    });
    if (controller.isSaleLoading.value) {
      _refreshSpinController.repeat();
    }

    // Load more when scrolled to bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !controller.isLoadMore.value &&
          controller.hasMorePages) {
        controller.getUserSales(loadMore: true);
      }
    });

    // Initial fetch
    if (controller.sales == null) {
      controller.getUserSales();
    }
  }

  @override
  void dispose() {
    _saleLoadingWorker.dispose();
    _refreshSpinController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show full screen shimmer on first load
      if (controller.isSaleLoading.value && controller.sales == null) {
        return const HomeShimmer();
      }

      // Show error with retry when initial load failed
      if (controller.salesError.value != null && controller.sales == null) {
        return LoginWrapper(
          title: "pos".tr,
          onWalletTap: () {
            final homeState = context
                .findAncestorStateOfType<_HomeScreenState>();
            homeState?._onItemTapped(1);
          },
          child: AppErrorWidget(
            message: controller.salesError.value!,
            onRetry: () async {
              await controller.getUserSales();
              if (controller.sales != null) controller.salesError.value = null;
            },
          ),
        );
      }

      final salesData = controller.sales?.message?.data ?? [];

      return LoginWrapper(
        title: "pos".tr,
        onWalletTap: () {
          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
          homeState?._onItemTapped(1);
        },
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.getCurrentBalance();
            await controller.getFamilyMember();
            await controller.getUserSales();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WalletCard(
                  balance: AppConstants.safeParseBalance(
                    AppConstants.currentBalance.toString(),
                  ),
                  onRecharge: () {
                    Get.to(WalletRechargeScreen());
                  },
                ),
                const SizedBox(height: 30),
                controller.isFamilyLoading.isTrue ||
                        controller.isUserLoading.isTrue
                    ? const ShimmerBox(height: 120, width: double.infinity)
                    : FamilyCard(
                        activeMembers:
                            AppConstants.familyMembers.value?.message?.total ??
                            0,
                        onAddMember: () {
                          final currentUser =
                              AppConstants.currentUser.value?.userData;
                          final totalMembers =
                              AppConstants
                                  .familyMembers
                                  .value
                                  ?.message
                                  ?.total ??
                              0;

                          if (currentUser?.parentId != null) {
                            Get.find<BottomNavController>().changeIndex(2);
                          } else if (totalMembers >= 10) {
                            SnackbarHelper.showError(
                              "max_family_members_error".tr,
                            );
                          } else {
                            Get.to(RegisterScreen(isFamilyMember: true));
                          }
                        },
                        onViewMember: () {
                          Get.find<BottomNavController>().changeIndex(2);
                        },
                      ),

                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'recent_orders'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.isSaleLoading.value
                          ? null
                          : () => controller.getUserSales(),
                      icon: RotationTransition(
                        turns: _refreshSpinController,
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).refreshIndicatorSemanticLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                salesData.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Lottie.asset(
                              "assets/lottie/no_data.json",
                              width: 140,
                              height: 140,
                              repeat: true,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_orders_yet'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: salesData.length + 1,
                        itemBuilder: (context, index) {
                          if (index < salesData.length) {
                            final order = salesData[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  AnalyticsService.logScreen(
                                    screenName: 'OrderDetail',
                                  );
                                  Get.to(OrderDetailScreen(order: order));
                                },
                                child: OrderTile(
                                  orderId: order.referenceCode ?? '',
                                  status: order.status ?? '',
                                  statusColor: getStatusColor(order.status),
                                  date: controller.formatOrderDate(order.date),
                                  amount: "SAR ${order.total ?? '0.00'}",
                                  delayAnimation: 100 * (index + 1),
                                ),
                              ),
                            );
                          } else {
                            if (controller.isLoadMore.value) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }
                        },
                      ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Map order status to color
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'on the way':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
