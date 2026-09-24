import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/controllers/register_controller.dart';
import 'package:pos_v2/models/get_all_store_response_model.dart';

class StoreSelectionStep extends StatefulWidget {
  final RegisterController controller;

  const StoreSelectionStep({super.key, required this.controller});

  @override
  State<StoreSelectionStep> createState() => _StoreSelectionStepState();
}

class _StoreSelectionStepState extends State<StoreSelectionStep> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  RegisterController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Stores> _filteredStores() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return controller.stores.toList();

    return controller.stores.where((store) {
      final name = (store.name ?? '').toLowerCase();
      final tenantId = (store.tenantId ?? '').toLowerCase();
      return name.contains(query) || tenantId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          controller.isFamilyMember
              ? 'select_child_store'.tr
              : 'select_preferred_store'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'change_later_settings'.tr,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        Obx(() {
          if (controller.isStoreLoading.value) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.stores.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: Text("no_stores_found".tr)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => controller.getAllStore(),
                  icon: const Icon(Icons.refresh),
                  label: Text("reload".tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          }

          final stores = _filteredStores();

          return Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'search_stores'.tr,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E8F1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E8F1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (stores.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 34,
                        color: Colors.blueGrey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'no_stores_match'.tr,
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: Scrollbar(
                    child: ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      itemCount: stores.length,
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        final tenantId = store.tenantId ?? "";

                        return Obx(
                          () => _AnimatedStoreTile(
                            storeName: store.name ?? "Store ${store.id}",
                            isSelected:
                                controller.selectedTenantId.value == tenantId,
                            onTap: () {
                              controller.selectedTenantId.value = tenantId;
                            },
                            index: index,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _AnimatedStoreTile extends StatefulWidget {
  final String storeName;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _AnimatedStoreTile({
    required this.storeName,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_AnimatedStoreTile> createState() => _AnimatedStoreTileState();
}

class _AnimatedStoreTileState extends State<_AnimatedStoreTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 100),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          color: widget.isSelected ? Colors.blue.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.isSelected ? Colors.blue : Colors.grey.shade300,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.store,
              color: widget.isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            title: Text(
              widget.storeName,
              style: TextStyle(
                fontWeight: widget.isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: widget.isSelected ? Colors.blue.shade800 : Colors.black,
              ),
            ),
            trailing: widget.isSelected
                ? Icon(Icons.check_circle, color: Colors.blue.shade700)
                : null,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
