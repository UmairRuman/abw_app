// lib/core/widgets/terms_checkbox.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/terms_and_conditions_screen.dart';
import '../theme/colors/app_colors_dark.dart';
import '../theme/text_styles/app_text_styles.dart';

class TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColorsDark.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: value ? activeColor : AppColorsDark.border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: activeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                  children: [
                    // ✅ Tappable T&C link
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsAndConditionsScreen(
                                  isPrivacyPolicy: false,
                                ),
                              ),
                            ),
                    ),
                    const TextSpan(text: ' and '),
                    // ✅ Tappable Privacy Policy link
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsAndConditionsScreen(
                                  isPrivacyPolicy: true,
                                ),
                              ),
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
}