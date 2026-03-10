import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../settings/data/models/contact_settings_model.dart';
import '../../../../settings/presentation/providers/contact_settings_provider.dart';

class CustomerContactScreen extends ConsumerStatefulWidget {
  const CustomerContactScreen({super.key});

  @override
  ConsumerState<CustomerContactScreen> createState() =>
      _CustomerContactScreenState();
}

class _CustomerContactScreenState extends ConsumerState<CustomerContactScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contactSettingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactSettingsProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Contact Us',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColorsDark.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          contactState is ContactSettingsLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : contactState is ContactSettingsLoaded
              ? _buildContent(contactState.settings)
              : contactState is ContactSettingsError
              ? _buildError(contactState.message)
              : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(ContactSettingsModel settings) {
    final hasAnything =
        settings.bannerUrl.isNotEmpty ||
        settings.whatsappNumber.isNotEmpty ||
        settings.phoneNumber.isNotEmpty;

    if (!hasAnything) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent_outlined,
              size: 72.sp,
              color: AppColorsDark.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No contact info available yet',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ─────────────────────────────────────────────────────
          if (settings.bannerUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(
                settings.bannerUrl,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // ── Heading ────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: AppColorsDark.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Get in Touch',
                style: AppTextStyles.titleLarge().copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'We\'re here to help. Reach us through any of the channels below.',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),

          // ── WhatsApp ───────────────────────────────────────────────────
          if (settings.whatsappNumber.isNotEmpty) ...[
            _buildContactCard(
              icon: Icons.chat,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              value: settings.whatsappNumber,
              subtitle: 'Chat with us on WhatsApp',
            ),
            SizedBox(height: 12.h),
          ],

          // ── Phone ──────────────────────────────────────────────────────
          if (settings.phoneNumber.isNotEmpty)
            _buildContactCard(
              icon: Icons.phone,
              iconColor: AppColorsDark.primary,
              label: 'Phone / PTCL',
              value: settings.phoneNumber,
              subtitle: 'Call us directly',
            ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: iconColor, size: 26.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(
        'Failed to load: $message',
        style: AppTextStyles.bodyMedium().copyWith(color: AppColorsDark.error),
      ),
    );
  }
}
