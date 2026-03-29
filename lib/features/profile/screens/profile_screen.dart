import 'service_provider_register_screen.dart';
import '../../auth/screens/kyc_screen.dart';
import 'account_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/ads_repository.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/screens/signin_screen.dart';
import '../../home/screens/subscriptions_screen.dart';
import 'my_ads_screen.dart';
import 'service_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AdsRepository _adsRepository = AdsRepository();
  final BookingRepository _bookingRepository = BookingRepository();
  int _myAdsCount = 0;
  int _myBookingsCount = 0;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      _loadAdsCount();
      _loadBookingsCount();
    }
  }

  Future<void> _loadAdsCount() async {
    try {
      final ads = await _adsRepository.getMyAds();
      if (mounted) {
        setState(() {
          _myAdsCount = ads.length;
        });
      }
    } catch (e) {
      print('❌ Error loading ads count: $e');
      // Silently fail, keep count at 0
    }
  }

  Future<void> _loadBookingsCount() async {
    try {
      final bookings = await _bookingRepository.getMyBookings();
      if (mounted) {
        setState(() {
          _myBookingsCount = bookings.length;
        });
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Token revoked')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
      } else {
        print('❌ Error loading bookings count: $e');
      }
      // Silently fail, keep count at 0
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _maskAadhar(String? aadhar) {
    if (aadhar == null || aadhar.isEmpty) return 'XXXX XXXX XXXX';
    if (aadhar.length <= 4) return aadhar;
    final lastFour = aadhar.substring(aadhar.length - 4);
    return 'XXXX XXXX $lastFour';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.fullName ?? 'Guest User';
        final phoneNumber = user?.phoneNumber ?? '+91 0000000000';
        final isAadharVerified = user?.isKycComplete ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Title
                    Text(
                      'Profile',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1A14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(userName),
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Name and Phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      phoneNumber,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Aadhar Verification
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAadharVerified
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAadharVerified
                                      ? Icons.verified_user
                                      : Icons.warning_amber_rounded,
                                  color: isAadharVerified
                                      ? AppColors.primary
                                      : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAadharVerified
                                          ? 'Aadhar Verified'
                                          : 'Aadhar Not Verified',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    isAadharVerified
                                        ? Text(
                                            _maskAadhar('123456785501'),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const KYCScreen()),
                                              );
                                            },
                                            child: Text(
                                              'Verify your Aadhar',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.orange,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // My Activity Section
                    Text(
                      'My Activity',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Ads',
                      subtitle: _myAdsCount == 0
                          ? 'No active listings'
                          : '$_myAdsCount active ${_myAdsCount == 1 ? 'listing' : 'listings'}',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyAdsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      icon: Icons.room_service_outlined,
                      title: 'My Service',
                      subtitle: _myBookingsCount == 0
                          ? 'No bookings'
                          : '$_myBookingsCount ${_myBookingsCount == 1 ? 'booking' : 'bookings'}',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServiceRequestsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Recent Ads Section
                    Text(
                      'Recent Ads',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentAdCard(
                      image: 'https://via.placeholder.com/100',
                      title: 'iPhone 13 Pro',
                      price: '₹ 65,000',
                      location: 'Mumbai, India',
                    ),
                    const SizedBox(height: 12),
                    _buildRecentAdCard(
                      image: 'https://via.placeholder.com/100',
                      title: 'iPhone 13 Pro',
                      price: '₹ 65,000',
                      location: 'Mumbai, India',
                    ),
                    const SizedBox(height: 32),

                    // Service Provider Section
                    Text(
                      'Service Provider',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildServiceProviderCard(),
                    const SizedBox(height: 32),

                    // Settings Section
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsCard(
                      icon: Icons.card_membership_outlined,
                      title: 'Subscriptions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      icon: Icons.settings_outlined,
                      title: 'Account Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: const Color(0xFF0B1A14),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Terms & Conditions',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '''Effective Date: 01/01/2026
Last Updated: 01/01/2026

Welcome to Onetap365 ("Company", "we", "our", "us"). These Terms & Conditions ("Terms") govern your use of the Onetap365 website, mobile application, and services (collectively, the "Platform").

By accessing or using Onetap365, you agree to comply with and be bound by these Terms. If you do not agree, please do not use the Platform.

1. About Onetap365
Onetap365 is an online marketplace platform that allows businesses, professionals, and service providers to list, promote, and manage their products and services through subscription-based plans.
We act only as a facilitator between users and customers and are not responsible for transactions conducted outside the platform.

2. Eligibility
To use the Platform:
- You must be at least 18 years old.
- You must provide accurate and complete registration information.
- You must not use the Platform for any unlawful activity.
We reserve the right to suspend or terminate accounts that violate these Terms.

3. Account Registration
Users must create an account to access certain features.
You are responsible for maintaining the confidentiality of your login credentials.
You are responsible for all activities conducted under your account.
Onetap365 reserves the right to refuse service, terminate accounts, or remove content at its discretion.

4. Subscription Plans & Payments
Onetap365 offers paid subscription plans.
Subscription fees must be paid in advance.
Plans may be monthly or yearly.
All payments are non-refundable unless otherwise stated.
Prices are subject to change with prior notice.
Failure to pay may result in suspension or removal of listings.
We may use third-party payment gateways to process payments securely.

5. Listings & Content
Users may post listings, images, descriptions, and contact information.
You agree that:
- All information provided is accurate and lawful.
- You own or have rights to the content you upload.
- Your content does not violate any intellectual property rights.
- Your listings do not promote illegal, fraudulent, or harmful services.
Onetap365 reserves the right to remove or modify listings that violate policies.

6. Prohibited Activities
Users shall not:
- Post false, misleading, or fraudulent information.
- Impersonate any individual or business.
- Upload harmful, offensive, or unlawful content.
- Attempt to hack, disrupt, or damage the Platform.
- Use automated tools to scrape data from the Platform.
Violation may result in permanent suspension.

7. Transactions & Liability
Onetap365 is a marketplace platform only.
We do not guarantee sales, leads, or profits.
We are not responsible for disputes between buyers and sellers.
Users are solely responsible for their business dealings.
We are not liable for losses, damages, or claims arising from transactions.
Users engage with each other at their own risk.

8. Intellectual Property
All trademarks, logos, branding, and software on the Platform are the property of Onetap365 unless otherwise stated.
You may not:
- Copy, reproduce, or distribute platform content without written permission.
- Use Onetap365 branding without authorization.

9. Privacy Policy
Your use of the Platform is also governed by our Privacy Policy, which explains how we collect and use personal information.

10. Termination
We may suspend or terminate access if:
- You violate these Terms.
- You fail to make payments.
- You engage in fraudulent activity.
You may cancel your account at any time; however, subscription fees are non-refundable.

11. Limitation of Liability
To the maximum extent permitted by law:
Onetap365 shall not be liable for indirect, incidental, or consequential damages.
Our total liability shall not exceed the amount paid by you in the last subscription period.

12. Indemnification
You agree to indemnify and hold harmless Onetap365, its directors, employees, and affiliates from any claims, damages, or legal expenses arising from your use of the Platform.

13. Changes to Terms
We may update these Terms at any time. Continued use of the Platform after updates constitutes acceptance of revised Terms.

14. Governing Law
These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts located in [Bangalore, India].''',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Close',
                                          style: GoogleFonts.inter(
                                              color: Colors.green)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      icon: Icons.logout,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () => _handleLogout(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAdCard({
    required String image,
    required String title,
    required String price,
    required String location,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceProviderCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ServiceProviderRegisterScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.work_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Become a Service Provider',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Offer your service and earn',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : Colors.white,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1A14),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SignInScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}
