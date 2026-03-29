import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/subscriptions_screen.dart';

class SubscribePlanDialog extends StatelessWidget {
  const SubscribePlanDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Subscribe to a Plan',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: const Text(
        'You have already posted an ad. To post more ads, please subscribe to a plan.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SubscriptionsScreen(),
              ),
            );
          },
          child: const Text('View Plans'),
        ),
      ],
    );
  }
}
