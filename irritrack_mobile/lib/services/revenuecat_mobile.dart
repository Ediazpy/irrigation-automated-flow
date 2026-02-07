/// Mobile implementation for RevenueCat
/// This file is only imported on mobile platforms (iOS/Android)

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/subscription.dart' as local;

bool _isInitialized = false;
CustomerInfo? _customerInfo;

Future<void> initializeRevenueCat(String apiKey) async {
  if (_isInitialized) {
    print('RevenueCat: Already initialized');
    return;
  }

  try {
    // Enable debug logs in debug mode
    await Purchases.setLogLevel(LogLevel.debug);

    // Configure with API key
    PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);

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

Future<void> login(String userId) async {
  if (!_isInitialized) return;

  try {
    final result = await Purchases.logIn(userId);
    _customerInfo = result.customerInfo;
    print('RevenueCat: Logged in user $userId');
  } on PlatformException catch (e) {
    print('RevenueCat: Login failed - ${e.message}');
  }
}

Future<void> logout() async {
  if (!_isInitialized) return;

  try {
    _customerInfo = await Purchases.logOut();
    print('RevenueCat: Logged out');
  } on PlatformException catch (e) {
    print('RevenueCat: Logout failed - ${e.message}');
  }
}

Future<CustomerInfo?> _getCustomerInfo() async {
  if (!_isInitialized) return null;

  try {
    _customerInfo = await Purchases.getCustomerInfo();
    return _customerInfo;
  } on PlatformException catch (e) {
    print('RevenueCat: Failed to get customer info - ${e.message}');
    return null;
  }
}

Future<bool> isProUser(String entitlementId) async {
  if (!_isInitialized) return false;

  try {
    final customerInfo = await _getCustomerInfo();
    if (customerInfo == null) return false;

    return customerInfo.entitlements.active.containsKey(entitlementId);
  } catch (e) {
    print('RevenueCat: Error checking pro status - $e');
    return false;
  }
}

Future<local.SubscriptionPlan> getActivePlan(String entitlementId) async {
  if (!_isInitialized) return local.SubscriptionPlan.free;

  try {
    final customerInfo = await _getCustomerInfo();
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

Future<Offerings?> _getOfferings() async {
  if (!_isInitialized) return null;

  try {
    return await Purchases.getOfferings();
  } on PlatformException catch (e) {
    print('RevenueCat: Failed to get offerings - ${e.message}');
    return null;
  }
}

Future<bool> _purchasePackage(Package package, String entitlementId) async {
  if (!_isInitialized) return false;

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

Future<bool> purchaseProduct(String productId, String entitlementId) async {
  if (!_isInitialized) return false;

  try {
    final offerings = await _getOfferings();
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

    return await _purchasePackage(targetPackage, entitlementId);
  } catch (e) {
    print('RevenueCat: Error purchasing product - $e');
    return false;
  }
}

Future<bool> restorePurchases(String entitlementId) async {
  if (!_isInitialized) return false;

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

Future<PaywallResult> presentPaywall(String entitlementId) async {
  if (!_isInitialized) {
    return PaywallResult.notPresented;
  }

  try {
    final paywallResult = await RevenueCatUI.presentPaywall();
    print('RevenueCat: Paywall result - $paywallResult');

    // Refresh customer info after paywall
    await _getCustomerInfo();

    return paywallResult;
  } on PlatformException catch (e) {
    print('RevenueCat: Failed to present paywall - ${e.message}');
    return PaywallResult.error;
  }
}

DateTime? getExpirationDate(String entitlementId) {
  if (_customerInfo == null) return null;

  final entitlement = _customerInfo!.entitlements.active[entitlementId];
  if (entitlement == null) return null;

  return entitlement.expirationDate != null
      ? DateTime.parse(entitlement.expirationDate!)
      : null;
}

bool willRenew(String entitlementId) {
  if (_customerInfo == null) return false;

  final entitlement = _customerInfo!.entitlements.active[entitlementId];
  return entitlement?.willRenew ?? false;
}
