// lib/core/screens/terms_and_conditions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/colors/app_colors_dark.dart';
import '../theme/text_styles/app_text_styles.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final bool isPrivacyPolicy; // toggle between T&C and Privacy Policy
  const TermsAndConditionsScreen({super.key, this.isPrivacyPolicy = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          isPrivacyPolicy ? 'Privacy Policy' : 'Terms & Conditions',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              isPrivacyPolicy
                  ? _buildPrivacyPolicy()
                  : _buildTermsAndConditions(),
        ),
      ),
    );
  }

  // ── Terms & Conditions ────────────────────────────────────────────────────

  List<Widget> _buildTermsAndConditions() {
    return [
      _buildTitle('Terms & Conditions'),
      _buildSubtitle('Effective Date: May 2026'),
      _buildSpacer(),

      _buildSectionTitle('1. Acceptance of Terms'),
      _buildBody(
        'By creating an account and using ABW Services, you agree to be bound '
        'by these Terms and Conditions. If you do not agree, please do not use '
        'the app.',
      ),
      _buildSpacer(),

      _buildSectionTitle('2. User Roles'),
      _buildBody(
        'The app supports three user roles: Customer, Rider, and Admin. '
        'Each role has specific permissions and responsibilities within the platform.',
      ),
      _buildSpacer(),

      _buildSectionTitle('3. Customer Obligations'),
      _buildBullet(
        'Provide accurate delivery address and contact information.',
      ),
      _buildBullet('Ensure someone is available to receive the order.'),
      _buildBullet(
        'Pay the agreed amount at the time of delivery (COD) or via e-wallet/bank transfer.',
      ),
      _buildBullet('Refrain from placing fraudulent or fake orders.'),
      _buildSpacer(),

      _buildSectionTitle('4. Rider Obligations'),
      _buildBullet(
        'Riders must be approved by the admin before accepting deliveries.',
      ),
      _buildBullet(
        'Riders are responsible for safe and timely delivery of orders.',
      ),
      _buildBullet(
        'Riders must keep their vehicle information accurate and up to date.',
      ),
      _buildBullet(
        'Riders must not share customer information with any third party.',
      ),
      _buildSpacer(),

      _buildSectionTitle('5. Payment Policy'),
      _buildBody(
        'The app supports Cash on Delivery (COD) as the primary payment method, '
        'with e-wallet and bank transfer as alternatives. These transactions involve '
        'real-world goods and are exempt from Google Play Billing API requirements. '
        'No digital goods or subscriptions are sold through the app.',
      ),
      _buildSpacer(),

      _buildSectionTitle('6. Order History'),
      _buildBody(
        'Customer order history is retained for the last 5 days for reference '
        'and support purposes. Orders older than 5 days are automatically removed '
        'from the customer view.',
      ),
      _buildSpacer(),

      _buildSectionTitle('7. Account Termination'),
      _buildBody(
        'Users may delete their accounts at any time from their profile screen. '
        'Upon deletion, login access is permanently removed. Order history may be '
        'retained for record-keeping and dispute resolution purposes.',
      ),
      _buildSpacer(),

      _buildSectionTitle('8. Limitation of Liability'),
      _buildBody(
        'ABW Services is not liable for delays caused by incorrect addresses, '
        'customer unavailability, or force majeure events. We are not responsible '
        'for the quality of food or goods delivered by partner stores.',
      ),
      _buildSpacer(),

      _buildSectionTitle('9. Changes to Terms'),
      _buildBody(
        'We reserve the right to update these Terms at any time. Continued use '
        'of the app after changes constitutes acceptance of the updated Terms.',
      ),
      _buildSpacer(),

      _buildSectionTitle('10. Contact'),
      _buildBody(
        'For any questions regarding these Terms, please contact us through the app support channel.',
      ),
      _buildSpacer(),
    ];
  }

  // ── Privacy Policy ────────────────────────────────────────────────────────

  List<Widget> _buildPrivacyPolicy() {
    return [
      _buildTitle('Privacy Policy'),
      _buildSubtitle('Effective Date: May 2026'),
      _buildSpacer(),

      _buildSectionTitle('1. Data We Collect'),
      _buildBody('We collect the following information per user role:'),
      _buildBullet(
        'Customer: Name, email, phone number, delivery address, order history (last 5 days), payment method.',
      ),
      _buildBullet(
        'Rider: Name, email, phone number, vehicle type, vehicle number, license number, precise location (foreground & background during active delivery).',
      ),
      _buildBullet('Admin: Name, email, phone number.'),
      _buildSpacer(),

      _buildSectionTitle('2. How We Use Your Data'),
      _buildBullet('To process and deliver orders.'),
      _buildBullet('To assign riders to orders and track deliveries.'),
      _buildBullet('To send order status notifications.'),
      _buildBullet('To manage accounts and resolve disputes.'),
      _buildBullet('To verify identity during onboarding.'),
      _buildSpacer(),

      _buildSectionTitle('3. Data Sharing'),
      _buildBody('We share limited data between roles only as needed:'),
      _buildBullet(
        'Customer name, phone, and static delivery address are shared with the assigned rider for delivery purposes only.',
      ),
      _buildBullet(
        'Rider name and phone number are shown to the customer during active delivery.',
      ),
      _buildBullet(
        'Admin has access to customer and rider data for platform management only.',
      ),
      _buildBullet('We do NOT sell your data to any third parties.'),
      _buildSpacer(),

      _buildSectionTitle('4. Location Data'),
      _buildBody(
        'Rider location is tracked in the foreground and background during active '
        'deliveries using ACCESS_FINE_LOCATION and ACCESS_BACKGROUND_LOCATION permissions. '
        'This is used solely for delivery tracking and is never shared with third parties. '
        'Customer live GPS location is NOT tracked or shared — only the static delivery '
        'address pin is used.',
      ),
      _buildSpacer(),

      _buildSectionTitle('5. Data Retention'),
      _buildBullet('Customer order history: last 5 days only.'),
      _buildBullet(
        'Rider delivery records: retained for operational purposes.',
      ),
      _buildBullet(
        'Account data: retained until account deletion is requested.',
      ),
      _buildSpacer(),

      _buildSectionTitle('6. Permissions Used'),
      _buildBullet('ACCESS_FINE_LOCATION — Rider delivery tracking.'),
      _buildBullet(
        'ACCESS_BACKGROUND_LOCATION — Rider tracking while app is minimized.',
      ),
      _buildBullet(
        'FOREGROUND_SERVICE — Keeps location tracking active with a visible notification.',
      ),
      _buildBullet(
        'POST_NOTIFICATIONS — Order updates and delivery alerts for all users.',
      ),
      _buildBullet('CAMERA (optional) — Rider proof of delivery photos.'),
      _buildBullet('INTERNET — Required for all app functionality.'),
      _buildSpacer(),

      _buildSectionTitle('7. Your Rights'),
      _buildBullet(
        'You may delete your account at any time from the Profile screen.',
      ),
      _buildBullet('You may request correction of inaccurate data.'),
      _buildBullet('You may contact us to request access to your stored data.'),
      _buildSpacer(),

      _buildSectionTitle('8. Security'),
      _buildBody(
        'All data is stored securely using Firebase (Google Cloud). Access to '
        'admin-level data is restricted to authorized personnel only.',
      ),
      _buildSpacer(),

      _buildSectionTitle('9. Contact Us'),
      _buildBody(
        'For privacy concerns or data requests, please contact us through the in-app support channel.',
      ),
      _buildSpacer(),
    ];
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildTitle(String text) => Padding(
    padding: EdgeInsets.only(bottom: 4.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.textPrimary,
      ),
    ),
  );

  Widget _buildSubtitle(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: TextStyle(fontSize: 13.sp, color: AppColorsDark.textSecondary),
    ),
  );

  Widget _buildSectionTitle(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.primary,
      ),
    ),
  );

  Widget _buildBody(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        color: AppColorsDark.textSecondary,
        height: 1.6,
      ),
    ),
  );

  Widget _buildBullet(String text) => Padding(
    padding: EdgeInsets.only(left: 8.w, bottom: 6.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6.h, right: 8.w),
          child: Container(
            width: 5.w,
            height: 5.w,
            decoration: const BoxDecoration(
              color: AppColorsDark.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColorsDark.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSpacer() => SizedBox(height: 16.h);
}
