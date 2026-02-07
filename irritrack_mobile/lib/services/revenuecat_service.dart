import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/subscription.dart' as local;

/// RevenueCat service for handling in-app purchases and subscriptions
class RevenueCatService {
  // Your RevenueCat API key
  static const String _apiKey = 'test_dALHGnXJUDKifLOpOZqDvrIsxCR';

  // Entitlement identifier (set this in RevenueCat dashboard)
  static const String entitlementId = 'Irrigation Automated Flow Pro';

  // Product identifiers (set these in RevenueCat dashboard)
  static const String monthlyProductId = 'monthly';
  static const String yearlyProductId = 'yearly';

  static bool _isInitialized = false;
  static CustomerInfo? _customerInfo;

  /// Initialize RevenueCat SDK
  static Future<void> initialize() async {
    if (kIsWeb) {
      print('RevenueCat: Web platform not supported, skipping initialization');
      return;
    }

    if (_isInitialized) {
      print('RevenueCat: Already initialized');
      return;
    }

    try {
      // Enable debug logs in debug mode
      await Purchases.setLogLevel(LogLevel.debug);

      // Configure with API key
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);

      await Purchases.configure(configuration);
      _isInitialized = true;

      // Get initial customer info
      _customerInfo = await Purchases.getCustomerInfo();

      print('RevenueCat: Initialized successfully');
      print('RevenueCat: User ID: ${await Purchases.appUserID}');
    } on PlatformException catch (e) {
      print('RevenueCat: Failed to initialize - ${e.message}');
    }
  }

  /// Login a user to RevenueCat (for syncing purchases across devices)
  static Future<void> login(String userId) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      final result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
      print('RevenueCat: Logged in user $userId');
    } on PlatformException catch (e) {
      print('RevenueCat: Login failed - ${e.message}');
    }
  }

  /// Logout the current user
  static Future<void> logout() async {
    if (kIsWeb || !_isInitialized) return;

    try {
      _customerInfo = await Purchases.logOut();
      print('RevenueCat: Logged out');
    } on PlatformException catch (e) {
      print('RevenueCat: Logout failed - ${e.message}');
    }
  }

  /// Get current customer info
  static Future<CustomerInfo?> getCustomerInfo() async {
    if (kIsWeb || !_isInitialized) return null;

    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo;
    } on PlatformException catch (e) {
      print('RevenueCat: Failed to get customer info - ${e.message}');
      return null;
    }
  }

  /// Check if user has active subscription (pro entitlement)
  static Future<bool> isProUser() async {
    if (kIsWeb) return false;
    if (!_isInitialized) await initialize();

    try {
      final customerInfo = await getCustomerInfo();
      if (customerInfo == null) return false;

      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      print('RevenueCat: Error checking pro status - $e');
      return false;
    }
  }

  /// Get the active subscription plan
  static Future<local.SubscriptionPlan> getActivePlan() async {
    if (kIsWeb) return local.SubscriptionPlan.free;
    if (!_isInitialized) await initialize();

    try {
      final customerInfo = await getCustomerInfo();
      if (customerInfo == null) return local.SubscriptionPlan.free;

      final entitlement = customerInfo.entitlements.active[entitlementId];
      if (entitlement == null) return local.SubscriptionPlan.free;

      // Determine plan based on product identifier
      final productId = entitlement.productIdentifier;

      if (productId.contains('solo')) {
        return local.SubscriptionPlan.solo;
      } else if (productId.contains('team')) {
        return local.SubscriptionPlan.team;
      } else if (productId.contains('business')) {
        return local.SubscriptionPlan.business;
      } else if (productId.contains('enterprise')) {
        return local.SubscriptionPlan.enterprise;
      }

      // Default to solo if subscribed but unknown product
      return local.SubscriptionPlan.solo;
    } catch (e) {
      print('RevenueCat: Error getting active plan - $e');
      return local.SubscriptionPlan.free;
    }
  }

  /// Get available offerings (products)
  static Future<Offerings?> getOfferings() async {
    if (kIsWeb || !_isInitialized) return null;

    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      print('RevenueCat: Failed to get offerings - ${e.message}');
      return null;
    }
  }

  /// Purchase a package
  static Future<bool> purchasePackage(Package package) async {
    if (kIsWeb || !_isInitialized) return false;

    try {
      _customerInfo = await Purchases.purchasePackage(package);
      return _customerInfo?.entitlements.active.containsKey(entitlementId) ?? false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        print('RevenueCat: Purchase cancelled by user');
      } else {
        print('RevenueCat: Purchase failed - ${e.message}');
      }
      return false;
    }
  }

  /// Purchase a specific product by ID
  static Future<bool> purchaseProduct(String productId) async {
    if (kIsWeb || !_isInitialized) return false;

    try {
      final offerings = await getOfferings();
      if (offerings == null || offerings.current == null) {
        print('RevenueCat: No offerings available');
        return false;
      }

      // Find the package with the matching product
      Package? targetPackage;
      for (final package in offerings.current!.availablePackages) {
        if (package.storeProduct.identifier == productId) {
          targetPackage = package;
          break;
        }
      }

      if (targetPackage == null) {
        print('RevenueCat: Product $productId not found');
        return false;
      }

      return await purchasePackage(targetPackage);
    } catch (e) {
      print('RevenueCat: Error purchasing product - $e');
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    if (kIsWeb || !_isInitialized) return false;

    try {
      _customerInfo = await Purchases.restorePurchases();
      final isActive = _customerInfo?.entitlements.active.containsKey(entitlementId) ?? false;
      print('RevenueCat: Purchases restored, pro active: $isActive');
      return isActive;
    } on PlatformException catch (e) {
      print('RevenueCat: Restore failed - ${e.message}');
      return false;
    }
  }

  /// Present the RevenueCat paywall
  static Future<PaywallResult> presentPaywall() async {
    if (kIsWeb || !_isInitialized) {
      return PaywallResult.notPresented;
    }

    try {
      final paywallResult = await RevenueCatUI.presentPaywall();
      print('RevenueCat: Paywall result - $paywallResult');

      // Refresh customer info after paywall
      await getCustomerInfo();

      return paywallResult;
    } on PlatformException catch (e) {
      print('RevenueCat: Failed to present paywall - ${e.message}');
      return PaywallResult.error;
    }
  }

  /// Present paywall if user is not pro
  static Future<PaywallResult> presentPaywallIfNeeded() async {
    if (kIsWeb || !_isInitialized) {
      return PaywallResult.notPresented;
    }

    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
      print('RevenueCat: Paywall if needed result - $paywallResult');

      // Refresh customer info after paywall
      await getCustomerInfo();

      return paywallResult;
    } on PlatformException catch (e) {
      print('RevenueCat: Failed to present paywall - ${e.message}');
      return PaywallResult.error;
    }
  }

  /// Get subscription expiration date
  static DateTime? getExpirationDate() {
    if (_customerInfo == null) return null;

    final entitlement = _customerInfo!.entitlements.active[entitlementId];
    if (entitlement == null) return null;

    return entitlement.expirationDate != null
        ? DateTime.parse(entitlement.expirationDate!)
        : null;
  }

  /// Check if subscription will renew
  static bool willRenew() {
    if (_customerInfo == null) return false;

    final entitlement = _customerInfo!.entitlements.active[entitlementId];
    return entitlement?.willRenew ?? false;
  }

  /// Get the management URL for the subscription
  static String? getManagementUrl() {
    return _customerInfo?.managementURL;
  }

  /// Listen to customer info updates
  static void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (kIsWeb || !_isInitialized) return;

    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Remove customer info listener
  static void removeCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (kIsWeb || !_isInitialized) return;

    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  /// Set user attributes for targeting and analytics
  static Future<void> setUserAttributes({
    String? email,
    String? displayName,
    String? phoneNumber,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      if (email != null) await Purchases.setEmail(email);
      if (displayName != null) await Purchases.setDisplayName(displayName);
      if (phoneNumber != null) await Purchases.setPhoneNumber(phoneNumber);
    } catch (e) {
      print('RevenueCat: Error setting attributes - $e');
    }
  }

  /// Set custom attributes
  static Future<void> setCustomAttribute(String key, String value) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      await Purchases.setAttributes({key: value});
    } catch (e) {
      print('RevenueCat: Error setting custom attribute - $e');
    }
  }
}
