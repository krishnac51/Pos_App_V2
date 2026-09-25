import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:pos_v2/constants/app_colors.dart';

Future<void> showAccessCodeSheet(
  BuildContext context, {
  required String name,
  required String? accessCode,
  bool accessCodeEnabled = false,
  required bool canEdit,
  required Future<bool> Function(String accessCode, bool enabled)? onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AccessCodeSheet(
      name: name,
      accessCode: accessCode,
      accessCodeEnabled: accessCodeEnabled,
      canEdit: canEdit,
      onSave: onSave,
    ),
  );
}

class AccessCodeSheet extends StatefulWidget {
  final String name;
  final String? accessCode;
  final bool accessCodeEnabled;
  final bool canEdit;
  final Future<bool> Function(String accessCode, bool enabled)? onSave;

  const AccessCodeSheet({
    super.key,
    required this.name,
    required this.accessCode,
    this.accessCodeEnabled = false,
    required this.canEdit,
    required this.onSave,
  });

  @override
  State<AccessCodeSheet> createState() => _AccessCodeSheetState();
}

class _AccessCodeSheetState extends State<AccessCodeSheet> {
  late final TextEditingController _codeController;
  bool _isEditing = false;
  bool _isVisible = false;
  bool _isSaving = false;
  late bool _isEnabled = widget.accessCodeEnabled;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.accessCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _code => _codeController.text.trim();

  Future<void> _save() async {
    if (!RegExp(r'^\d{4}$').hasMatch(_code)) {
      Get.snackbar(
        'access_code'.tr,
        'access_code_four_digits'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        backgroundColor: const Color(0xFF172B4D),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);
    final saved = await widget.onSave?.call(_code, _isEnabled) ?? false;
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final displayedCode = widget.accessCode?.trim().isNotEmpty == true
        ? widget.accessCode!.trim()
        : '----';
    final visibleCode = _isEditing ? _code : displayedCode;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E1EC),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'access_code'.tr,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14253D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  IconButton(
                    onPressed: () => setState(() => _isVisible = !_isVisible),
                    icon: Icon(
                      _isVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    color: Colors.blueGrey.shade500,
                    tooltip: _isVisible ? 'hide'.tr : 'show'.tr,
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.blueGrey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.canEdit && _isEditing
                  ? 'update_access_code_desc'.tr
                  : 'access_code_view_desc'.tr,
              style: TextStyle(
                height: 1.4,
                fontSize: 14,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 18),
            if (_isEditing)
              _buildEditor(context)
            else
              _buildCodeCard(visibleCode),
            if (widget.canEdit) ...[
              const SizedBox(height: 14),
              _buildEnableSwitch(),
            ],
            const SizedBox(height: 22),
            if (widget.canEdit && !_isEditing)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded, size: 19),
                  label: Text('update_access_code'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
            else if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => setState(() {
                              _isEditing = false;
                              _codeController.text = widget.accessCode ?? '';
                              _isEnabled = widget.accessCodeEnabled;
                            }),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('save_changes'.tr),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E8F1)),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _isEnabled,
        activeColor: AppColors.primaryBlue,
        title: Text(
          'enable_access_code'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14253D),
          ),
        ),
        subtitle: Text(
          'enable_access_code_desc'.tr,
          style: TextStyle(fontSize: 12.5, color: Colors.blueGrey.shade600),
        ),
        onChanged: _isSaving
            ? null
            : (value) => setState(() {
                _isEnabled = value;
                _isEditing = true;
              }),
      ),
    );
  }

  Widget _buildCodeCard(String code) {
    final safeCode = code.length == 4 ? code : '----';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E8F1)),
      ),
      // Digits always read left to right, also in Arabic.
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...List.generate(4, (index) {
            final value = safeCode[index];
            return Container(
              width: 48,
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6E2F0)),
              ),
              child: Text(
                _isVisible || value == '-' ? value : '\u2022',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14253D),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PinCodeTextField(
        appContext: context,
        length: 4,
        controller: _codeController,
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
          fieldWidth: 54,
          activeColor: AppColors.primaryBlue,
          selectedColor: AppColors.primaryBlue,
          inactiveColor: const Color(0xFFD6E2F0),
          activeFillColor: const Color(0xFFEAF4FF),
          selectedFillColor: Colors.white,
          inactiveFillColor: Colors.white,
        ),
      ),
    );
  }
}
