/// Stub implementation for RevenueCat on web platform
/// All methods return empty/false values since RevenueCat doesn't support web

import '../models/subscription.dart' as local;

Future<void> initializeRevenueCat(String apiKey) async {
  // No-op on web
}

Future<void> login(String userId) async {
  // No-op on web
}

Future<void> logout() async {
  // No-op on web
}

Future<bool> isProUser(String entitlementId) async {
  return false;
}

Future<local.SubscriptionPlan> getActivePlan(String entitlementId) async {
  return local.SubscriptionPlan.free;
}

Future<bool> purchaseProduct(String productId, String entitlementId) async {
  return false;
}

Future<bool> restorePurchases(String entitlementId) async {
  return false;
}

Future<dynamic> presentPaywall(String entitlementId) async {
  return null;
}

DateTime? getExpirationDate(String entitlementId) {
  return null;
}

bool willRenew(String entitlementId) {
  return false;
}
