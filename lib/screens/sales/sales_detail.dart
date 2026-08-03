import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_sales_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final Data order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Order #${order.referenceCode ?? ''}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔵 BLUE CARD (UNCHANGED)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.blue.withOpacity(0.9)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(order.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.status?.toUpperCase() ?? 'UNKNOWN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SAR ${order.total ?? '0.00'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.date),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ⚪ ORDER INFORMATION (CARD → CONTAINER)
            Container(
              decoration: _whiteShadowDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Reference',
                    value: order.referenceCode ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Order Date',
                    value: _formatDate(order.date),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    context: context,
                    icon: Icons.payment_outlined,
                    label: 'Payment Status',
                    value: _getPaymentStatus(order),
                    valueColor: _getPaymentStatusColor(order),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ⚪ PAYMENT SUMMARY (CARD → CONTAINER)
            Container(
              decoration: _whiteShadowDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _paymentRow(
                    'Total Amount',
                    'SAR ${order.total ?? '0.00'}',
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _paymentRow(
                    'Amount Paid',
                    'SAR ${order.paid ?? '0.00'}',
                    textColor: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _paymentRow(
                    'Amount Due',
                    'SAR ${order.due ?? '0.00'}',
                    textColor: Colors.orange,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🛍 ITEMS HEADER (UNCHANGED)
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Order Items (${order.items?.length ?? 0})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),

            /// ⚪ ITEMS LIST (STYLE UPDATED ONLY)
            ...?order.items?.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: _whiteShadowDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.thumbnail != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.thumbnail!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name ?? 'Unnamed Product',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.quantity ?? 0} ${item.unit ?? ''}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'SAR ${item.total ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SAR ${item.price ?? '0.00'} per unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 💳 PAY NOW BUTTON (UNCHANGED)
            if (order.due != null && double.parse(order.due ?? '0') > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ===== WHITE SHADOW DECORATION (MATCHES OrderTile) =====
  BoxDecoration _whiteShadowDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // ===== REST OF YOUR CODE (UNCHANGED) =====

  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'on the way':
      case 'shipped':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatus(Data order) {
    final due = double.tryParse(order.due ?? '0') ?? 0;
    final paid = double.tryParse(order.paid ?? '0') ?? 0;
    final total = double.tryParse(order.total ?? '0') ?? 0;

    if (due <= 0) return 'Paid';
    if (paid > 0 && due < total) return 'Partially Paid';
    return 'Pending';
  }

  Color _getPaymentStatusColor(Data order) {
    switch (_getPaymentStatus(order)) {
      case 'Paid':
        return Colors.green;
      case 'Partially Paid':
        return Colors.orange;
      case 'Pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat(
        'EEEE, MMMM dd, yyyy • hh:mm a',
      ).format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}
