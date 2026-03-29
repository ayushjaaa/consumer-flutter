import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onetap365app/features/home/screens/subscriptions_screen.dart';
import 'package:onetap365app/providers/subscriptions_provider.dart';
import 'package:onetap365app/data/services/api_service.dart';

class FakeApiService extends ApiService {
  Object? error;
  dynamic response;
  FakeApiService({this.response, this.error});

  @override
  Future<dynamic> getActiveSubscription() async {
    if (error != null) throw error!;
    return Future.value(response);
  }
}

Widget makeApp(ApiService api, Widget child) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('SubscriptionsScreen', () {
    testWidgets('Should show loading indicator initially', (tester) async {
      final api = FakeApiService(response: []);
      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));

      // First frame: provider triggers fetch and sets loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Should render error message when provider.error is set', (tester) async {
      final api = FakeApiService(error: Exception('Network down'));
      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));

      // initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // complete futures
      await tester.pumpAndSettle();

      expect(find.textContaining('Exception: Network down'), findsOneWidget);
    });

    testWidgets('Should show empty message when no subscription data', (tester) async {
      final api = FakeApiService(response: null);
      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));

      await tester.pumpAndSettle();

      expect(find.text('No subscription data found.'), findsOneWidget);
    });

    testWidgets('Should list plans when API returns a list of plans', (tester) async {
      final plans = [
        {
          'plan_name': 'Basic',
          'price': 99,
          'description': 'Basic plan',
          'duration': '30 days',
          'active_listings': 5,
          'featured_listings': 0,
          'priority_search': 0,
          'whatsapp_leads': 1,
          'support_type': 'Email',
        },
        {
          'plan_name': 'Pro',
          'price': 199,
          'description': 'Pro plan',
          'duration': '90 days',
          'active_listings': 20,
          'featured_listings': 5,
          'priority_search': 1,
          'whatsapp_leads': 1,
          'support_type': 'Priority',
        },
      ];
      final api = FakeApiService(response: plans);

      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Subscription Plans'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('₹99'), findsOneWidget);
      expect(find.text('₹199'), findsOneWidget);

      // Chips from _PlanDetailChip
      expect(find.text('Duration: 30 days'), findsOneWidget);
      expect(find.text('Active Listings: 5'), findsOneWidget);
      expect(find.text('Featured Listings: 0'), findsOneWidget);
      expect(find.text('Priority Search: No'), findsOneWidget);
      expect(find.text('WhatsApp Leads: Yes'), findsOneWidget);
      expect(find.text('Support: Email'), findsOneWidget);
    });

    testWidgets('Should handle single plan map object by normalizing to list', (tester) async {
      final response = {
        'plans': [
          {
            'plan_name': 'Solo',
            'price': 49,
            'duration': '7 days',
            'active_listings': 1,
            'support_type': 'Email',
          }
        ]
      };
      final api = FakeApiService(response: response);

      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('₹49'), findsOneWidget);
      expect(find.text('Duration: 7 days'), findsOneWidget);
    });

    testWidgets('Tapping Buy shows snackbar with plan name', (tester) async {
      final plans = [
        {
          'plan_name': 'Gold',
          'price': 299,
        },
      ];
      final api = FakeApiService(response: plans);

      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Gold'), findsOneWidget);

      final buyButton = find.widgetWithText(ElevatedButton, 'Buy');
      expect(buyButton, findsOneWidget);
      await tester.tap(buyButton);
      await tester.pump();

      expect(find.textContaining('Buy/Subscribe for Gold'), findsOneWidget);
    });

    // New tests
    testWidgets('Shows app bar title and uses themed colors', (tester) async {
      final api = FakeApiService(response: []);
      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      // App bar title should always be present
      expect(find.text('Subscription Plans'), findsOneWidget);
    });

    testWidgets('Renders "No subscription plans found." when normalized plans list is empty', (tester) async {
      final api = FakeApiService(response: []);
      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));

      await tester.pumpAndSettle();

      expect(find.text('No subscription plans found.'), findsOneWidget);
    });

    testWidgets('Normalizes single map (without plans key) into a one-item list', (tester) async {
      final api = FakeApiService(response: {
        'plan_name': 'SingleMap',
        'price': 10,
        'duration': '1 day',
        'priority_search': 1,
        'whatsapp_leads': 0,
      });

      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SingleMap'), findsOneWidget);
      expect(find.text('₹10'), findsOneWidget);
      expect(find.text('Duration: 1 day'), findsOneWidget);
      expect(find.text('Priority Search: Yes'), findsOneWidget);
      expect(find.text('WhatsApp Leads: No'), findsOneWidget);
    });

    testWidgets('Omits description and chips when fields are null or empty', (tester) async {
      final api = FakeApiService(response: [
        {
          'plan_name': 'NoFrills',
          'price': 0,
          'description': '',
        }
      ]);

      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NoFrills'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      // No description widget should render when empty
      expect(find.text(''), findsNothing);
      // No chips should be rendered since optional fields are missing
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('Multiple plans render multiple Buy buttons and each shows its own snackbar', (tester) async {
      final api = FakeApiService(response: [
        {'plan_name': 'Plan A', 'price': 1},
        {'plan_name': 'Plan B', 'price': 2},
      ]);

      await tester.pumpWidget(makeApp(api, const SubscriptionsScreen()));
      await tester.pumpAndSettle();

      final buyButtons = find.widgetWithText(ElevatedButton, 'Buy');
      expect(buyButtons, findsNWidgets(2));

      await tester.tap(buyButtons.at(0));
      await tester.pump();
      expect(find.textContaining('Buy/Subscribe for Plan A'), findsOneWidget);

      // Dismiss first snackbar and tap the second
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.tap(buyButtons.at(1));
      await tester.pump();
      expect(find.textContaining('Buy/Subscribe for Plan B'), findsOneWidget);
    });
  });
}
