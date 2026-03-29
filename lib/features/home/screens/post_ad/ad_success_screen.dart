import 'package:flutter/material.dart';
import '../../widgets/continue_button.dart';

class AdSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E221A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ad Posted Successfully!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your ad has been posted and will be reviewed shortly.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Go to Home Button
              ContinueButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                text: 'Go to Home',
              ),
              const SizedBox(height: 16),
              // View My Ads Button (Optional)
              ContinueButton(
                onPressed: () {
                  // TODO: Navigate to My Ads screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                text: 'View My Ads',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
