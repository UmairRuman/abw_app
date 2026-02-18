// lib/main.dart

import 'dart:developer';

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
  try {
    await Supabase.initialize(
      url:
          'https://wgvihnnjrhmfjauruszu.supabase.co', // From Supabase dashboard
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indndmlobm5qcmhtZmphdXJ1c3p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMTAyNDEsImV4cCI6MjA4NjY4NjI0MX0.u3wDUutvfHAJqIwE3_72MCh_Tz8xaPbCAZIKTZJD-14', // From Supabase dashboard
    );
    log('✅ Supabase initialized successfully');
  } catch (e) {
    log('❌ Supabase initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

// ✅ ADD HELPER GETTER
final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
