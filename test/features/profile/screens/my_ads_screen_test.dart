import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onetap365app/features/profile/screens/my_ads_screen.dart';
import 'package:onetap365app/data/repositories/ads_repository.dart';
import 'package:onetap365app/data/models/ad_model.dart';
import 'package:onetap365app/core/constants/app_colors.dart';

// Mock AdsRepository
class MockAdsRepository extends AdsRepository {
  List<Ad>? mockAds;
  Exception? mockError;
  bool deleteSuccess = true;
  int deleteCallCount = 0;
  int getMyAdsCallCount = 0;

  @override
  Future<List<Ad>> getMyAds() async {
    getMyAdsCallCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    if (mockError != null) {
      throw mockError!;
    }
    return mockAds ?? [];
  }

  @override
  Future<bool> deleteAd(int adId) async {
    deleteCallCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return deleteSuccess;
  }
}

// Helper function to create test app
Widget makeTestApp(Widget child) {
  return MaterialApp(
    home: child,
  );
}

// Helper function to create sample ads
List<Ad> createSampleAds() {
  return [
    Ad(
      id: 1,
      itemType: 'SELL',
      catId: 1,
      categoryName: 'Electronics',
      name: 'iPhone 13',
      description: 'Brand new iPhone 13',
      mrp: '80000',
      sellingPrice: '75000',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
      photos: ['https://example.com/photo1.jpg'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Ad(
      id: 2,
      itemType: 'RENT',
      catId: 2,
      categoryName: 'Real Estate',
      name: '2BHK Apartment',
      description: 'Spacious apartment',
      mrp: '25000',
      sellingPrice: '20000',
      city: 'Delhi',
      state: 'Delhi',
      pincode: '110001',
      photos: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
}

void main() {
  group('MyAdsScreen', () {
    testWidgets('Should show loading indicator initially', (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = [];

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // First frame should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Should display error message when API fails', (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockError = Exception('Network error');

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show error icon and message
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load ads'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Should show empty state when user has no ads', (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = [];

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.text('No ads posted yet'), findsOneWidget);
      expect(find.text('Your posted ads will appear here'), findsOneWidget);
    });

    testWidgets('Should display list of ads when data is loaded successfully',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show app bar title
      expect(find.text('My Ads'), findsOneWidget);

      // Should show ad cards
      expect(find.text('iPhone 13'), findsOneWidget);
      expect(find.text('2BHK Apartment'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Real Estate'), findsOneWidget);
      expect(find.text('₹ 75000'), findsOneWidget);
      expect(find.text('₹ 20000'), findsOneWidget);

      // Should show location
      expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
      expect(find.text('Delhi, Delhi'), findsOneWidget);

      // Should show Active status badges
      expect(find.text('Active'), findsNWidgets(2));

      // Should show edit and delete buttons
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
      expect(find.byIcon(Icons.delete), findsNWidgets(2));
    });

    testWidgets('Should refresh ads list when pull-to-refresh is triggered',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for initial load
      await tester.pumpAndSettle();

      // Initial call count should be 1
      expect(mockRepo.getMyAdsCallCount, 1);

      // Trigger pull-to-refresh
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Call count should increase to 2
      expect(mockRepo.getMyAdsCallCount, 2);
    });

    testWidgets('Should navigate to listing detail screen when ad card is tapped',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Tap on first ad card
      await tester.tap(find.text('iPhone 13'));
      await tester.pumpAndSettle();

      // Note: In a real test, we would verify navigation using a mock navigator
      // For now, we just verify the tap doesn't cause errors
    });

    testWidgets('Should show delete confirmation dialog when delete button is pressed',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Tap delete button on first ad
      final deleteButtons = find.byIcon(Icons.delete);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Ad'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this ad?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Should delete ad and refresh list when deletion is confirmed',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();
      mockRepo.deleteSuccess = true;

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Tap delete button on first ad
      final deleteButtons = find.byIcon(Icons.delete);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Ad deleted successfully'), findsOneWidget);

      // Should have called deleteAd
      expect(mockRepo.deleteCallCount, 1);

      // Should have refreshed the list (getMyAds called twice: initial + refresh)
      expect(mockRepo.getMyAdsCallCount, 2);
    });

    testWidgets('Should show error snackbar when ad deletion fails',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();
      mockRepo.deleteSuccess = false;

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Tap delete button on first ad
      final deleteButtons = find.byIcon(Icons.delete);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Failed to delete ad'), findsOneWidget);

      // Should have called deleteAd
      expect(mockRepo.deleteCallCount, 1);
    });

    testWidgets('Should not delete ad when deletion is cancelled',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Tap delete button on first ad
      final deleteButtons = find.byIcon(Icons.delete);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Cancel deletion
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should not have called deleteAd
      expect(mockRepo.deleteCallCount, 0);

      // Should not show any snackbar
      expect(find.text('Ad deleted successfully'), findsNothing);
      expect(find.text('Failed to delete ad'), findsNothing);
    });

    testWidgets('Should display time ago correctly for recent ads',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show time ago for ads
      expect(find.text('2 days ago'), findsOneWidget);
      expect(find.text('5 hours ago'), findsOneWidget);
    });

    testWidgets('Should show placeholder icon when ad has no photos',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Second ad has no photos, should show placeholder
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('Should retry loading ads when retry button is pressed',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockError = Exception('Network error');

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for error state
      await tester.pumpAndSettle();

      // Initial call count should be 1
      expect(mockRepo.getMyAdsCallCount, 1);

      // Clear error and set mock data
      mockRepo.mockError = null;
      mockRepo.mockAds = createSampleAds();

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should have called getMyAds again
      expect(mockRepo.getMyAdsCallCount, 2);

      // Should now show ads
      expect(find.text('iPhone 13'), findsOneWidget);
    });

    testWidgets('Should display app bar with back button and title',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = [];

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show app bar elements
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('My Ads'), findsOneWidget);
    });

    testWidgets('Should show edit button with correct icon and tooltip',
        (tester) async {
      final mockRepo = MockAdsRepository();
      mockRepo.mockAds = createSampleAds();

      await tester.pumpWidget(makeTestApp(const MyAdsScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show edit buttons
      final editButtons = find.byIcon(Icons.edit);
      expect(editButtons, findsNWidgets(2));

      // Verify tooltip (long press to show tooltip)
      await tester.longPress(editButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('Edit Ad'), findsOneWidget);
    });
  });
}
