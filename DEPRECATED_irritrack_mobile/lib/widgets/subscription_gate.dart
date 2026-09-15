import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../screens/subscription/pricing_screen.dart';

/// Widget that gates features based on subscription status
class SubscriptionGate extends StatelessWidget {
  final SubscriptionService subscriptionService;
  final Widget child;
  final String? featureName;
  final bool requiresActiveSubscription;

  const SubscriptionGate({
    Key? key,
    required this.subscriptionService,
    required this.child,
    this.featureName,
    this.requiresActiveSubscription = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!requiresActiveSubscription) {
      return child;
    }

    final hasAccess = subscriptionService.hasActiveSubscription;

    if (hasAccess) {
      return child;
    }

    // Show upgrade prompt
    return _UpgradePrompt(
      subscriptionService: subscriptionService,
      featureName: featureName,
    );
  }
}

class _UpgradePrompt extends StatelessWidget {
  final SubscriptionService subscriptionService;
  final String? featureName;

  const _UpgradePrompt({
    required this.subscriptionService,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              featureName != null
                  ? '$featureName requires a subscription'
                  : 'This feature requires a subscription',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subscriptionService.isTrialExpired
                  ? 'Your free trial has expired'
                  : 'Upgrade to unlock all features',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showPricing(context),
              icon: const Icon(Icons.upgrade),
              label: const Text('View Plans'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPricing(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricingScreen(
          subscriptionService: subscriptionService,
        ),
      ),
    );
  }
}

/// Shows a dialog when user tries to exceed their plan limits
class LimitReachedDialog extends StatelessWidget {
  final String limitType; // 'users' or 'properties'
  final int currentCount;
  final int maxCount;
  final SubscriptionService subscriptionService;

  const LimitReachedDialog({
    Key? key,
    required this.limitType,
    required this.currentCount,
    required this.maxCount,
    required this.subscriptionService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Limit Reached'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'ve reached your $limitType limit.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Current plan: ${subscriptionService.currentPlan?.name ?? "Free"}'),
          Text('$limitType limit: $maxCount'),
          Text('Current $limitType: $currentCount'),
          const SizedBox(height: 16),
          const Text(
            'Upgrade your plan to add more.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PricingScreen(
                  subscriptionService: subscriptionService,
                ),
              ),
            );
          },
          child: const Text('Upgrade'),
        ),
      ],
    );
  }

  static Future<bool> checkAndShow({
    required BuildContext context,
    required SubscriptionService subscriptionService,
    required String limitType,
    required int currentCount,
  }) async {
    final plan = subscriptionService.currentPlan;
    if (plan == null) return false;

    int maxCount;
    bool canAdd;

    if (limitType == 'users') {
      maxCount = plan.maxUsers;
      canAdd = subscriptionService.canAddUser(currentCount);
    } else {
      maxCount = plan.maxProperties;
      canAdd = subscriptionService.canAddProperty(currentCount);
    }

    if (canAdd) return true;

    await showDialog(
      context: context,
      builder: (context) => LimitReachedDialog(
        limitType: limitType,
        currentCount: currentCount,
        maxCount: maxCount,
        subscriptionService: subscriptionService,
      ),
    );

    return false;
  }
}

/// Trial banner to show at top of screens
class TrialBanner extends StatelessWidget {
  final SubscriptionService subscriptionService;

  const TrialBanner({
    Key? key,
    required this.subscriptionService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscription = subscriptionService.currentSubscription;
    if (subscription == null) return const SizedBox.shrink();

    // Show nothing if active paid subscription
    if (subscription.status == SubscriptionStatus.active &&
        subscription.plan != SubscriptionPlan.free) {
      return const SizedBox.shrink();
    }

    // Trial banner
    if (subscription.status == SubscriptionStatus.trialing) {
      final daysLeft = subscriptionService.trialDaysRemaining;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: daysLeft <= 3 ? Colors.orange : Colors.teal,
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                daysLeft <= 3
                    ? 'Trial ending soon! $daysLeft days left'
                    : 'Free trial: $daysLeft days remaining',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => _showPricing(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
    }

    // Expired trial banner
    if (subscriptionService.isTrialExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.red,
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Your trial has expired',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => _showPricing(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Subscribe'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showPricing(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricingScreen(
          subscriptionService: subscriptionService,
        ),
      ),
    );
  }
}
