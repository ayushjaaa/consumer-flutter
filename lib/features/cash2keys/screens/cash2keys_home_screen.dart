import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/constants/app_colors.dart';
import 'enrollment_screen.dart';
import 'check_status_screen.dart';

class Cash2KeysHomeScreen extends StatefulWidget {
  @override
  _Cash2KeysHomeScreenState createState() => _Cash2KeysHomeScreenState();
}

class _Cash2KeysHomeScreenState extends State<Cash2KeysHomeScreen> {
  double investmentAmount = 10000;
  int durationMonths = 12;

  // Enrollment status: 'not_enrolled', 'pending', 'approved', 'rejected'
  String enrollmentStatus = 'not_enrolled';

  static const String staticUniqueId = 'C2K-123456';

  // Calculates the maturity amount for a recurring monthly investment (SIP) with monthly compounding
  // Formula: FV = P * [((1 + r)^n - 1) / r] * (1 + r)
  // Where:
  // P = monthly investment
  // r = monthly interest rate
  // n = number of months
  double get expectedReturns {
    final double annualRate = 0.12;
    final double monthlyRate = annualRate / 12;
    final int n = durationMonths;
    final double P = investmentAmount;
    if (monthlyRate == 0) return P * n;
    final double fv = P * (pow(1 + monthlyRate, n) - 1) / monthlyRate;
    return fv;
  }

  double get totalAmount => expectedReturns;

  // Get enrollment status details
  Map<String, dynamic> getEnrollmentStatusDetails() {
    switch (enrollmentStatus) {
      case 'approved':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
          'text': 'Approved',
          'subtext': 'Your enrollment has been approved',
          'showButton': false,
        };
      case 'pending':
        return {
          'icon': Icons.hourglass_top,
          'color': const Color(0xFFF59E0B),
          'text': 'Pending Review',
          'subtext': 'Your application is under review',
          'showButton': true,
          'buttonText': 'Check Status',
        };
      case 'rejected':
        return {
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444),
          'text': 'Application Rejected',
          'subtext': 'Please reapply or contact support',
          'showButton': true,
          'buttonText': 'Reapply',
        };
      default:
        return {
          'icon': Icons.info,
          'color': AppColors.primary,
          'text': 'Not Enrolled',
          'subtext': 'Start your Cash2Keys journey today',
          'showButton': false,
        };
    }
  }

  Widget _buildEnrollmentStatusCard() {
    final statusDetails = getEnrollmentStatusDetails();
    return GestureDetector(
      onTap: () {
        // Navigate to check status screen when status card is tapped
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CheckStatusScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF174C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (statusDetails['color'] as Color).withOpacity(0.3),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: (statusDetails['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    statusDetails['icon'] as IconData,
                    color: statusDetails['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusDetails['text'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDetails['subtext'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (statusDetails['showButton'] == true)
              Column(
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusDetails['color'] as Color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (enrollmentStatus == 'rejected') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EnrollmentScreen(),
                            ),
                          );
                        } else {
                          // Navigate to check status screen for pending applications
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CheckStatusScreen(),
                            ),
                          );
                        }
                      },
                      child: Text(
                        statusDetails['buttonText'] as String? ??
                            'Check Status',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF0E221A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cash2Keys',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    'ID: $staticUniqueId',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Application Enrollment Status Card
            _buildEnrollmentStatusCard(),
            const SizedBox(height: 24),
            // Invest Smart Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF174C2E),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.trending_up,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Invest Smart',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        SizedBox(height: 4),
                        Text('Grow Your Wealth',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 8),
                        Text(
                            'Join our Cash to Keys program and turn your investment into valuable property assets with guaranteed returns.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Secure & Flexible
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF174C2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: const [
                        Icon(Icons.verified_user,
                            color: AppColors.primary, size: 28),
                        SizedBox(height: 8),
                        Text('Secure',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('100% Safe',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF174C2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: const [
                        Icon(Icons.access_time,
                            color: AppColors.primary, size: 28),
                        SizedBox(height: 8),
                        Text('Flexible',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Choose Duration',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Calculate Returns
            const Text('Calculate Returns',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF174C2E),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Investment Amount',
                      style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: investmentAmount,
                          min: 1000,
                          max: 100000,
                          divisions: 99,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            setState(() => investmentAmount = value);
                          },
                        ),
                      ),
                      Text('₹ ${investmentAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Duration (Months)',
                      style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: durationMonths.toDouble(),
                          min: 1,
                          max: 48,
                          divisions: 47,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            setState(() => durationMonths = value.toInt());
                          },
                        ),
                      ),
                      Text('${durationMonths} months',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Expected Returns',
                      style: TextStyle(color: Colors.white)),
                  Text('₹ ${expectedReturns.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Total Amount', style: TextStyle(color: Colors.white)),
                  Text('₹ ${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                        'By adding ₹10,000 every month for 48 months and applying 12% annual interest',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // How It Works
            const Text('How It Works',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    const Text('Invest',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 44),
                  child: Text('Choose your investment amount and duration',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('2',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    const Text('Grow',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 44),
                  child: Text('Your money grows with guaranteed returns',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('3',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    const Text('Convert',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 44),
                  child: Text('Choose returns to property assets or cash out',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Enroll Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EnrollmentScreen(),
                    ),
                  );
                },
                child: const Text('Enroll Now',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
