import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late Future<List<Map<String, dynamic>>> _subscriptionsFuture;
  late Razorpay _razorpay;
  late ApiService _apiService;

  // Store current payment details for backend confirmation
  Map<String, dynamic>? _currentPaymentOrder;

  // Razorpay Test Keys
  static const String RAZORPAY_KEY_ID = 'rzp_test_SUdRBcsuXaJvyM';
  static const String RAZORPAY_KEY_SECRET = 'y1Ip6i8ofpKgAQRlvmWzSKnA';

  @override
  void initState() {
    super.initState();
    print('\n========== 🚀 SUBSCRIPTIONS SCREEN INITIALIZED ==========');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('🔑 Razorpay Key ID: $RAZORPAY_KEY_ID');

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    print('✅ Razorpay event listeners attached');

    _apiService = Provider.of<ApiService>(context, listen: false);
    _subscriptionsFuture = _fetchSubscriptions(_apiService);
    print('======================================================\n');
  }

  /// Create order on backend before Razorpay payment
  Future<Map<String, dynamic>?> _createPaymentOrder(
    Map<String, dynamic> plan,
  ) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      // Check if user ID is null or empty
      if (userId == null || userId.isEmpty) {
        print('\n========== ❌ AUTHENTICATION ERROR ==========');
        print('❌ User ID is missing or empty');
        print('👤 User object exists: ${authProvider.user != null}');
        if (authProvider.user != null) {
          print('📧 Email: ${authProvider.user?.email}');
          print('📱 Phone: ${authProvider.user?.phoneNumber}');
          print('⚠️  But ID field is empty!');
          print(
              '⚠️  Tell backend developer: User model must return "id" or "_id" field');
        }
        print('=============================================\n');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Authentication error: User ID not found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      print('\n========== 📦 STEP 1: CREATE PAYMENT ORDER ==========');
      print('⏰ Timestamp: ${DateTime.now()}');
      print('👤 User ID: $userId');
      print('📋 Plan ID: ${plan['id']}');
      print('💰 Plan Name: ${plan['plan_name']}');

      // Convert price safely from String or number
      final price = double.tryParse(plan['price'].toString()) ?? 0.0;
      final priceInPaise = (price * 100).toInt();
      print('💵 Amount: ₹${price.toStringAsFixed(2)} ($priceInPaise paise)');
      print('📧 Email: ${authProvider.user?.email}');
      print('📱 Phone: ${authProvider.user?.phoneNumber}');

      // Call backend to create order
      print('🌐 Sending request to: /create-payment-order');
      final response = await _apiService.post(
        '/create-payment-order', // Adjust endpoint as needed
        body: {
          'user_id': userId,
          'plan_id': plan['id'],
          'plan_name': plan['plan_name'],
          'amount': plan['price'],
          'currency': 'INR',
          'email': authProvider.user?.email ?? '',
          'phone': authProvider.user?.phoneNumber ?? '',
        },
      );

      print('✅ Response received from backend:');
      print('   Success: ${response['success']}');
      print('   Order ID: ${response['data']?['order_id']}');
      print('   Razorpay Order ID: ${response['data']?['razorpay_order_id']}');

      if (response['success'] == true) {
        final orderData = {
          'order_id': response['data']['order_id'],
          'razorpay_order_id': response['data']['razorpay_order_id'],
          'user_id': userId,
          'plan_id': plan['id'],
          'plan_name': plan['plan_name'],
          'amount': plan['price'],
        };
        print('✅ Payment order created successfully!');
        print('======================================================\n');
        return orderData;
      } else {
        throw Exception(response['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      print('❌ ERROR creating order:');
      print('   Exception: $e');

      // Check if it's a 404 endpoint not found error
      if (e.toString().contains('404') ||
          e.toString().contains('Resource not found')) {
        print('\n⚠️  BACKEND ENDPOINT NOT IMPLEMENTED!');
        print(
            '📌 Backend developer needs to create: POST /api/create-payment-order');
        print('📋 See RAZORPAY_INTEGRATION.md for endpoint specifications');
      }

      print('======================================================\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error: ${e.toString().contains('404') ? 'Backend endpoint not implemented' : 'Payment order creation failed'}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  /// Confirm payment with backend after successful Razorpay payment
  Future<void> _confirmPaymentWithBackend(
    PaymentSuccessResponse response,
  ) async {
    try {
      if (_currentPaymentOrder == null) {
        print('\n========== ❌ ERROR: NO PAYMENT ORDER FOUND ==========');
        print('Payment order details are missing!');
        print('======================================================\n');
        return;
      }

      print('\n========== 📤 STEP 2: CONFIRM PAYMENT WITH BACKEND ==========');
      print('⏰ Timestamp: ${DateTime.now()}');
      print('💳 Payment ID: ${response.paymentId}');
      print('🔗 Razorpay Order ID: ${response.orderId}');
      print('✍️  Signature: ${response.signature?.substring(0, 20)}...');
      print('📋 Plan: ${_currentPaymentOrder!['plan_name']}');
      print('💰 Amount: ₹${_currentPaymentOrder!['amount']}');

      print('🌐 Sending request to: /confirm-payment');
      final confirmResponse = await _apiService.post(
        '/confirm-payment', // Adjust endpoint as needed
        body: {
          'user_id': _currentPaymentOrder!['user_id'],
          'plan_id': _currentPaymentOrder!['plan_id'],
          'order_id': _currentPaymentOrder!['order_id'],
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'amount': _currentPaymentOrder!['amount'],
          'plan_name': _currentPaymentOrder!['plan_name'],
        },
      );

      print('✅ Response received from backend:');
      print('   Success: ${confirmResponse['success']}');
      print('   Message: ${confirmResponse['message']}');

      if (confirmResponse['success'] == true) {
        print('\n🎉 PAYMENT CONFIRMATION SUCCESSFUL!');
        print(
            '✅ Subscription activated: ${_currentPaymentOrder!['plan_name']}');
        print('✅ User subscription is now active');
        print('========================================================\n');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subscription activated! ${_currentPaymentOrder!['plan_name']} plan is now active.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Clear payment order details
        _currentPaymentOrder = null;
      }
    } catch (e) {
      print('❌ ERROR confirming payment:');
      print('   Exception: $e');
      print('========================================================\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming payment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('\n========== ✅ RAZORPAY PAYMENT SUCCESSFUL ==========');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('💳 Payment ID: ${response.paymentId}');
    print('🔗 Order ID: ${response.orderId}');
    print('✍️  Signature: ${response.signature?.substring(0, 30)}...');
    print('====================================================\n');

    // Show success message (no backend confirmation needed for test mode)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Successful! ${_currentPaymentOrder?['plan_name'] ?? 'Plan'} activated.',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _currentPaymentOrder = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('\n========== ❌ RAZORPAY PAYMENT ERROR ==========');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('❌ Error Code: ${response.code}');
    print('❌ Error Message: ${response.message}');
    print('================================================\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed! ${response.message}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('\n========== 💳 EXTERNAL WALLET SELECTED ==========');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('💳 Wallet Name: ${response.walletName}');
    print('================================================\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Open Razorpay payment dialog (Test mode - no backend required)
  Future<void> _openRazorpay(Map<String, dynamic> plan) async {
    // Convert price safely from String or number
    print('\n========== 🧮 CALCULATING RAZORPAY AMOUNT ==========');
    print('Raw plan[\'price\'] value: ${plan['price']}');
    print('Raw plan[\'price\'] type: ${plan['price'].runtimeType}');

    final priceValue = double.tryParse(plan['price'].toString()) ?? 0.0;
    print('Parsed priceValue: $priceValue');

    final amount = (priceValue * 100).toInt(); // Amount in paise
    print('❗ FINAL AMOUNT IN PAISE: $amount');
    print('❗ WHICH EQUALS: ₹${(amount / 100).toStringAsFixed(2)}');
    print('======================================================\n');

    final planName = plan['plan_name'] ?? 'Subscription Plan';

    // Store plan details for payment success handler
    _currentPaymentOrder = {
      'plan_id': plan['id'],
      'plan_name': planName,
      'amount': priceValue,
      'user_id': 'test_user', // Placeholder for test
    };

    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.user?.fullName ?? 'User';
    final userEmail = authProvider.user?.email ?? '';
    final userPhone = authProvider.user?.phoneNumber ?? '';

    var options = {
      'key': RAZORPAY_KEY_ID,
      'amount': amount,
      'currency': 'INR',
      'name': 'OneTap365',
      'description': planName,
      'retry': {'enabled': true, 'max_count': 3},
      'prefill': {
        'name': userName,
        'email': userEmail,
        'contact': userPhone,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      print('\n========== 🔓 OPENING RAZORPAY PAYMENT DIALOG ==========');
      print('⏰ Timestamp: ${DateTime.now()}');
      print('🧪 MODE: TEST (No backend required)');
      print('💰 Display Amount: ₹${priceValue.toStringAsFixed(2)}');
      print('💳 Razorpay Amount (paise): ${amount}');
      print('📋 Plan: ${planName}');
      print('👤 User: ${userName}');
      print('📧 Email: ${userEmail}');
      print('📱 Phone: ${userPhone}');
      print('=========================================================\n');

      _razorpay.open(options);
    } catch (e) {
      print('❌ ERROR opening Razorpay:');
      print('   Exception: $e');
      print('=========================================================\n');
      debugPrint('Error opening Razorpay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  Future<List<Map<String, dynamic>>> _fetchSubscriptions(
      ApiService apiService) async {
    try {
      print('\n========== 📥 FETCHING SUBSCRIPTION PLANS ==========');
      print('⏰ Timestamp: ${DateTime.now()}');
      print('🌐 Endpoint: /active-subscriptions');

      final response = await apiService.getActiveSubscription();

      // Handle different response formats
      List<Map<String, dynamic>> plans = [];

      if (response is List) {
        plans = response.cast<Map<String, dynamic>>();
      } else if (response is Map) {
        if (response['data'] is List) {
          plans = (response['data'] as List).cast<Map<String, dynamic>>();
        } else if (response['plans'] is List) {
          plans = (response['plans'] as List).cast<Map<String, dynamic>>();
        }
      }

      print('✅ Fetched ${plans.length} subscription plans:');
      for (int i = 0; i < plans.length; i++) {
        print(
            '   Plan ${i + 1}: ${plans[i]['plan_name']} - ₹${plans[i]['price']}');
      }
      print('=========================================================\n');

      return plans;
    } catch (e) {
      print('\n========== ❌ ERROR FETCHING SUBSCRIPTIONS ==========');
      print('   Exception: $e');
      print('=========================================================\n');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subscriptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error loading subscriptions',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        final apiService =
                            Provider.of<ApiService>(context, listen: false);
                        _subscriptionsFuture = _fetchSubscriptions(apiService);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return const Center(
              child: Text(
                'No subscription plans available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 600,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final isPopular = index == 1; // Second plan is popular

                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 16, bottom: 8),
                        decoration: BoxDecoration(
                          color: isPopular
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPopular
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isPopular ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isPopular
                                  ? AppColors.primary.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Plan name
                              Text(
                                plan['plan_name']?.toString() ?? 'Plan',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Price
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '₹${plan['price'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if ((plan['price'] ?? 0) != 0)
                                      TextSpan(
                                        text: ' / month',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Features list
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (plan['active_listings'] != null)
                                      _FeatureRow(
                                          '${plan['active_listings']} Regular Ads'),
                                    if (plan['featured_listings'] != null)
                                      _FeatureRow(
                                          '${plan['featured_listings']} Featured Ads'),
                                    if (plan['top_ads'] != null)
                                      _FeatureRow('${plan['top_ads']} Top Ads'),
                                    if (plan['bumped_ads'] != null)
                                      _FeatureRow(
                                          '${plan['bumped_ads']} Ads will be bumped up'),
                                    if (plan['support_type'] != null)
                                      _FeatureRow(
                                          plan['support_type'].toString()),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Buy button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPopular
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    foregroundColor: isPopular
                                        ? Colors.white
                                        : Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    _openRazorpay(plan);
                                  },
                                  child: Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isPopular
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;

  const _FeatureRow(this.feature);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✓ ',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
