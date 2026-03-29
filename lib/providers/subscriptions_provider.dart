import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class SubscriptionsProvider extends ChangeNotifier {
  final ApiService apiService;
  bool isLoading = false;
  String? error;
  dynamic activeSubscription;

  SubscriptionsProvider({required this.apiService});

  Future<void> fetchActiveSubscription() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await apiService.getActiveSubscription();
      activeSubscription = result;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
