import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'select_category_screen.dart';
import '../../widgets/continue_button.dart';

class PostAdTypeScreen extends StatelessWidget {
  const PostAdTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E221A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post an Ad',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(1, 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Choose Listing Type',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTypeCard(
                    context,
                    'Sell',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SelectCategoryScreen(type: 'Sell'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTypeCard(
                    context,
                    'Rent',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SelectCategoryScreen(type: 'Rent'),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ContinueButton(
                    onPressed: () {},
                    text: 'Continue',
                    isEnabled: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index < currentStep
                    ? AppColors.primary
                    : const Color(0xFF1a2e2e),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, String type, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1a2e2e)),
        ),
        child: Center(
          child: Text(
            type,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF22C55E),
            ),
          ),
        ),
      ),
    );
  }
}
