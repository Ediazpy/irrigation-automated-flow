import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

/// Service for managing subscriptions across web (Stripe) and mobile (RevenueCat)
class SubscriptionService {
  static const String _subscriptionKey = 'irritrack_subscription';
  static const String _customerIdKey = 'irritrack_customer_id';

  // Stripe configuration (for web)
  // TODO: Replace with your actual Stripe keys
  static const String stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';
  static const String stripePriceIdSoloMonthly = 'price_solo_monthly';
  static const String stripePriceIdSoloYearly = 'price_solo_yearly';
  static const String stripePriceIdTeamMonthly = 'price_team_monthly';
  static const String stripePriceIdTeamYearly = 'price_team_yearly';
  static const String stripePriceIdBusinessMonthly = 'price_business_monthly';
  static const String stripePriceIdBusinessYearly = 'price_business_yearly';

  // RevenueCat configuration (for mobile)
  // TODO: Replace with your actual RevenueCat keys
  static const String revenueCatApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String revenueCatApiKeyIOS = 'YOUR_REVENUECAT_IOS_KEY';
  static const String revenueCatEntitlementId = 'premium';

  Subscription? _currentSubscription;
  String? _customerId;

  Subscription? get currentSubscription => _currentSubscription;
  String? get customerId => _customerId;

  /// Initialize the subscription service
  Future<void> initialize(String userEmail) async {
    _customerId = await _getOrCreateCustomerId(userEmail);
    await _loadSubscription();

    // If no subscription exists, create a trial
    if (_currentSubscription == null ||
        _currentSubscription!.status == SubscriptionStatus.none) {
      await _startTrial();
    }
  }

  /// Get or create a customer ID for this user
  Future<String> _getOrCreateCustomerId(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    String? customerId = prefs.getString(_customerIdKey);

    if (customerId == null) {
      // Generate a simple customer ID based on email and timestamp
      customerId = 'cus_${userEmail.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_customerIdKey, customerId);
    }

    return customerId;
  }

  /// Load subscription from local storage and sync with server
  Future<void> _loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionJson = prefs.getString(_subscriptionKey);

    if (subscriptionJson != null) {
      try {
        final Map<String, dynamic> json =
            Map<String, dynamic>.from(await _parseJson(subscriptionJson));
        _currentSubscription = Subscription.fromJson(json);
      } catch (e) {
        print('Error loading subscription: $e');
      }
    }

    // Sync with Firestore for the latest status
    await _syncWithServer();
  }

  /// Parse JSON string (simple implementation)
  Future<Map<String, dynamic>> _parseJson(String jsonString) async {
    // Simple JSON parsing - in production use dart:convert
    try {
      return Map<String, dynamic>.from(
        (await FirebaseFirestore.instance
            .collection('subscriptions')
            .doc(_customerId)
            .get())
            .data() ?? {}
      );
    } catch (e) {
      return {};
    }
  }

  /// Save subscription to local storage
  Future<void> _saveSubscription() async {
    if (_currentSubscription == null) return;

    final prefs = await SharedPreferences.getInstance();
    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(_customerId)
        .set(_currentSubscription!.toJson());
  }

  /// Sync subscription status with server
  Future<void> _syncWithServer() async {
    if (_customerId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(_customerId)
          .get();

      if (doc.exists && doc.data() != null) {
        _currentSubscription = Subscription.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error syncing subscription: $e');
    }
  }

  /// Start a free trial
  Future<void> _startTrial() async {
    if (_customerId == null) return;

    _currentSubscription = Subscription.trial(customerId: _customerId!);
    await _saveSubscription();
  }

  /// Check if user has an active subscription
  bool get hasActiveSubscription {
    return _currentSubscription?.isValid ?? false;
  }

  /// Check if trial has expired
  bool get isTrialExpired {
    return _currentSubscription?.isTrialExpired ?? false;
  }

  /// Get days remaining in trial
  int get trialDaysRemaining {
    return _currentSubscription?.trialDaysRemaining ?? 0;
  }

  /// Get current plan details
  PlanDetails? get currentPlan {
    return _currentSubscription?.planDetails;
  }

  /// Check if user can add more users based on their plan
  bool canAddUser(int currentUserCount) {
    if (_currentSubscription == null) return false;
    return _currentSubscription!.canAddUser(currentUserCount);
  }

  /// Check if user can add more properties based on their plan
  bool canAddProperty(int currentPropertyCount) {
    if (_currentSubscription == null) return false;
    return _currentSubscription!.canAddProperty(currentPropertyCount);
  }

  /// Get the Stripe price ID for a plan
  String getStripePriceId(SubscriptionPlan plan, bool isYearly) {
    switch (plan) {
      case SubscriptionPlan.solo:
        return isYearly ? stripePriceIdSoloYearly : stripePriceIdSoloMonthly;
      case SubscriptionPlan.team:
        return isYearly ? stripePriceIdTeamYearly : stripePriceIdTeamMonthly;
      case SubscriptionPlan.business:
        return isYearly ? stripePriceIdBusinessYearly : stripePriceIdBusinessMonthly;
      default:
        return '';
    }
  }

  /// Create a Stripe checkout session (for web)
  /// This should call your backend to create a Stripe checkout session
  Future<String?> createStripeCheckoutSession({
    required SubscriptionPlan plan,
    required bool isYearly,
    required String successUrl,
    required String cancelUrl,
  }) async {
    if (!kIsWeb) return null;

    try {
      // In production, this would call your backend API
      // which creates a Stripe checkout session
      final priceId = getStripePriceId(plan, isYearly);

      // For now, return a placeholder
      // TODO: Implement backend call to create checkout session
      print('Creating Stripe checkout for price: $priceId');

      // Example of what the backend call would look like:
      // final response = await http.post(
      //   Uri.parse('https://your-backend.com/create-checkout-session'),
      //   body: {
      //     'priceId': priceId,
      //     'customerId': _customerId,
      //     'successUrl': successUrl,
      //     'cancelUrl': cancelUrl,
      //   },
      // );
      // return jsonDecode(response.body)['sessionUrl'];

      return null;
    } catch (e) {
      print('Error creating Stripe checkout: $e');
      return null;
    }
  }

  /// Handle successful Stripe payment (webhook or redirect)
  Future<void> handleStripeSuccess({
    required String subscriptionId,
    required SubscriptionPlan plan,
    required bool isYearly,
  }) async {
    if (_customerId == null) return;

    final now = DateTime.now();
    _currentSubscription = Subscription(
      id: subscriptionId,
      customerId: _customerId!,
      plan: plan,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: isYearly
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30)),
      isYearly: isYearly,
      stripeSubscriptionId: subscriptionId,
    );

    await _saveSubscription();
  }

  /// Initialize RevenueCat (for mobile)
  Future<void> initializeRevenueCat() async {
    if (kIsWeb) return;

    // TODO: Implement RevenueCat initialization
    // await Purchases.setDebugLogsEnabled(true);
    //
    // PurchasesConfiguration configuration;
    // if (Platform.isAndroid) {
    //   configuration = PurchasesConfiguration(revenueCatApiKeyAndroid);
    // } else {
    //   configuration = PurchasesConfiguration(revenueCatApiKeyIOS);
    // }
    //
    // await Purchases.configure(configuration);
    // await Purchases.logIn(_customerId!);
  }

  /// Purchase via RevenueCat (for mobile)
  Future<bool> purchaseWithRevenueCat(SubscriptionPlan plan, bool isYearly) async {
    if (kIsWeb) return false;

    try {
      // TODO: Implement RevenueCat purchase
      // final offerings = await Purchases.getOfferings();
      // final package = isYearly
      //     ? offerings.current?.annual
      //     : offerings.current?.monthly;
      //
      // if (package != null) {
      //   final purchaseResult = await Purchases.purchasePackage(package);
      //   // Handle purchase result
      //   return purchaseResult.customerInfo.entitlements.active.containsKey(revenueCatEntitlementId);
      // }

      return false;
    } catch (e) {
      print('Error with RevenueCat purchase: $e');
      return false;
    }
  }

  /// Check RevenueCat entitlements (for mobile)
  Future<void> checkRevenueCatEntitlements() async {
    if (kIsWeb) return;

    try {
      // TODO: Implement RevenueCat entitlement check
      // final customerInfo = await Purchases.getCustomerInfo();
      // if (customerInfo.entitlements.active.containsKey(revenueCatEntitlementId)) {
      //   // User has active subscription
      //   final entitlement = customerInfo.entitlements.active[revenueCatEntitlementId]!;
      //   // Update local subscription based on entitlement
      // }
    } catch (e) {
      print('Error checking RevenueCat entitlements: $e');
    }
  }

  /// Restore purchases (for mobile - required by App Store)
  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;

    try {
      // TODO: Implement RevenueCat restore
      // final customerInfo = await Purchases.restorePurchases();
      // return customerInfo.entitlements.active.containsKey(revenueCatEntitlementId);
      return false;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  /// Cancel subscription (redirect to appropriate portal)
  Future<String> getCancelUrl() async {
    if (kIsWeb) {
      // Return Stripe customer portal URL
      // In production, call your backend to create a portal session
      return 'https://billing.stripe.com/p/login/test';
    } else {
      // Return app store subscription management URL
      // iOS: https://apps.apple.com/account/subscriptions
      // Android: https://play.google.com/store/account/subscriptions
      return 'https://play.google.com/store/account/subscriptions';
    }
  }

  /// Manually set subscription (for testing or admin override)
  Future<void> setSubscription({
    required SubscriptionPlan plan,
    required SubscriptionStatus status,
    int durationDays = 30,
  }) async {
    if (_customerId == null) return;

    final now = DateTime.now();
    _currentSubscription = Subscription(
      id: 'manual_${now.millisecondsSinceEpoch}',
      customerId: _customerId!,
      plan: plan,
      status: status,
      startDate: now,
      endDate: now.add(Duration(days: durationDays)),
    );

    await _saveSubscription();
  }
}
