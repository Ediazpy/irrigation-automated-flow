import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../models/subscription.dart' as local;

// Conditional imports for RevenueCat (mobile only)
// ignore: depend_on_referenced_packages
import 'revenuecat_stub.dart'
    if (dart.library.io) 'revenuecat_mobile.dart' as revenuecat;

/// RevenueCat service for handling in-app purchases and subscriptions
/// This is a wrapper that delegates to platform-specific implementations
class RevenueCatService {
  // Your RevenueCat API key
  static const String _apiKey = 'test_dALHGnXJUDKifLOpOZqDvrIsxCR';

  // Entitlement identifier (set this in RevenueCat dashboard)
  static const String entitlementId = 'Irrigation Automated Flow Pro';

  // Product identifiers (set these in RevenueCat dashboard)
  static const String monthlyProductId = 'monthly';
  static const String yearlyProductId = 'yearly';

  /// Initialize RevenueCat SDK
  static Future<void> initialize() async {
    if (kIsWeb) {
      print('RevenueCat: Web platform not supported, skipping initialization');
      return;
    }
    await revenuecat.initializeRevenueCat(_apiKey);
  }

  /// Login a user to RevenueCat (for syncing purchases across devices)
  static Future<void> login(String userId) async {
    if (kIsWeb) return;
    await revenuecat.login(userId);
  }

  /// Logout the current user
  static Future<void> logout() async {
    if (kIsWeb) return;
    await revenuecat.logout();
  }

  /// Check if user has active subscription (pro entitlement)
  static Future<bool> isProUser() async {
    if (kIsWeb) return false;
    return await revenuecat.isProUser(entitlementId);
  }

  /// Get the active subscription plan
  static Future<local.SubscriptionPlan> getActivePlan() async {
    if (kIsWeb) return local.SubscriptionPlan.free;
    return await revenuecat.getActivePlan(entitlementId);
  }

  /// Purchase a specific product by ID
  static Future<bool> purchaseProduct(String productId) async {
    if (kIsWeb) return false;
    return await revenuecat.purchaseProduct(productId, entitlementId);
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    return await revenuecat.restorePurchases(entitlementId);
  }

  /// Present the RevenueCat paywall
  static Future<dynamic> presentPaywall() async {
    if (kIsWeb) return null;
    return await revenuecat.presentPaywall(entitlementId);
  }

  /// Get subscription expiration date
  static DateTime? getExpirationDate() {
    if (kIsWeb) return null;
    return revenuecat.getExpirationDate(entitlementId);
  }

  /// Check if subscription will renew
  static bool willRenew() {
    if (kIsWeb) return false;
    return revenuecat.willRenew(entitlementId);
  }
}
