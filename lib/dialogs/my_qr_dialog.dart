import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class MyQRDialog extends StatefulWidget {
  AnimationController animationController;

  MyQRDialog({super.key, required this.animationController});

  @override
  State<MyQRDialog> createState() => _MyQRDialogState();
}

class _MyQRDialogState extends State<MyQRDialog>
    with SingleTickerProviderStateMixin {
  String qrData = "";
  String displayText = "";
  bool useSmallText = false;
  late final Animation<double> _scaleAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    final userData = AppConstants.currentUser.value!.userData!;
    final currentCard = userData.currentCard?.trim();
    final userName = userData.username ?? "";

    if (currentCard == null || currentCard.isEmpty) {
      qrData = userName.isNotEmpty ? userName : "user";
      displayText = userName;
      useSmallText = false;
    } else {
      qrData = currentCard;
      displayText = currentCard;
      useSmallText = true;
    }
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeOutBack,
      ),
    );

    super.initState();
  }

  Future<void> _shareQR() async {
    final imageBytes = await _screenshotController.capture();
    if (imageBytes == null) {
      return;
    }

    final xfile = XFile.fromData(
      imageBytes,
      name: 'qr.png',
      mimeType: 'image/png',
    );
    await Share.shareXFiles([
      xfile,
    ], text: '${'my_qr_share_text'.tr}: $displayText');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Screenshot(
          controller: _screenshotController,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'my_qr'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'scan_qr_description'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrData)}',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 200,
                          height: 200,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.qr_code,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Display Field (username or current card)
                  TextField(
                    controller: TextEditingController(text: displayText)
                      ..selection = TextSelection.collapsed(
                        offset: displayText.length,
                      ),
                    readOnly: true,
                    textAlign: TextAlign.center,
                    maxLines: useSmallText ? 2 : 1,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: TextStyle(
                      fontSize: useSmallText ? 12 : 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: useSmallText ? 0.5 : 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'done'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Share Button
                  TextButton(
                    onPressed: _shareQR,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'share_now'.tr,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
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
      ),
    );
  }
}
