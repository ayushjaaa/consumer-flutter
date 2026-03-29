import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CheckStatusScreen extends StatefulWidget {
  const CheckStatusScreen({super.key});

  @override
  State<CheckStatusScreen> createState() => _CheckStatusScreenState();
}

class _CheckStatusScreenState extends State<CheckStatusScreen> {
  final TextEditingController referenceIdController = TextEditingController();
  bool isLoading = false;
  String? statusResult;
  String? statusMessage;

  @override
  void dispose() {
    referenceIdController.dispose();
    super.dispose();
  }

  void checkStatus() {
    if (referenceIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your reference ID')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      statusResult = null;
      statusMessage = null;
    });

    // Simulate API call with delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
        // Mock response based on reference ID pattern
        final refId = referenceIdController.text.toUpperCase();
        if (refId.startsWith('CK') || refId.contains('1')) {
          statusResult = 'approved';
          statusMessage =
              'Your enrollment has been approved! You can now invest.';
        } else if (refId.contains('2')) {
          statusResult = 'pending';
          statusMessage =
              'Your application is under review. We will notify you soon.';
        } else if (refId.contains('3')) {
          statusResult = 'rejected';
          statusMessage =
              'Your application was not approved. Please contact support for details.';
        } else {
          statusResult = 'not_found';
          statusMessage = 'Reference ID not found. Please check and try again.';
        }
      });
    });
  }

  Widget _buildStatusBadge() {
    if (statusResult == null) return const SizedBox.shrink();

    late Color badgeColor;
    late IconData badgeIcon;
    late String badgeText;

    switch (statusResult) {
      case 'approved':
        badgeColor = const Color(0xFF10B981);
        badgeIcon = Icons.check_circle;
        badgeText = 'Approved';
        break;
      case 'pending':
        badgeColor = const Color(0xFFF59E0B);
        badgeIcon = Icons.hourglass_top;
        badgeText = 'Pending';
        break;
      case 'rejected':
        badgeColor = const Color(0xFFEF4444);
        badgeIcon = Icons.cancel;
        badgeText = 'Rejected';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.info;
        badgeText = 'Not Found';
    }

    return Container(
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(badgeIcon, color: badgeColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (statusResult == 'rejected')
            Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Reapply',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

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
          'Check Status',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Icon(
                Icons.description,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'Track Your Application',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            const Text(
              'Enter your reference ID to check the current status of your Cash to Keys enrollment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            // Reference ID Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reference ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1A14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1a2e2e)),
                  ),
                  child: TextField(
                    controller: referenceIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'CK12345678',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Note
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Note:',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your reference ID was sent to you via email and SMS after completing the enrollment process.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Status Result
            if (statusResult != null) _buildStatusBadge(),
            const SizedBox(height: 32),
            // Check Status Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isLoading ? null : checkStatus,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  isLoading ? 'Checking...' : 'Check Status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
