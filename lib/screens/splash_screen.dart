import 'package:flutter/material.dart';
import '../core/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// App Icon
            const Icon(
              Icons.bloodtype,
              color: AppColors.textWhite,
              size: 90,
            ),

            const SizedBox(height: 24),

            /// App Title
            Text(
              "Blood Hero",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textWhite,
                fontSize: 30,
              ),
            ),

            const SizedBox(height: 12),

            /// Subtitle
            Text(
              "Save Lives ❤️",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textWhite.withOpacity(0.85),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}