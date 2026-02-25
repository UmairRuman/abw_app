// lib/main.dart

import 'dart:developer';

import 'package:abw_app/core/services/notification_service.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme/app_theme_dark.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ INITIALIZE NOTIFICATION SERVICE
  await NotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _refreshFCMTokenIfLoggedIn();
  }

  // ✅ REFRESH FCM TOKEN ON APP STARTUP (if user is logged in)
  Future<void> _refreshFCMTokenIfLoggedIn() async {
    final authState = ref.read(authProvider);

    if (authState is Authenticated) {
      // User is logged in, refresh FCM token
      await NotificationService().saveFCMTokenToFirestore(
        authState.user.id,
        authState.user.role.name,
      );

      log('✅ FCM token refreshed for ${authState.user.role.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    log('🔄 Main Build method');
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppThemeDark.darkTheme(), // Dark theme as default
          routerConfig: router,
        );
      },
    );
  }
}
