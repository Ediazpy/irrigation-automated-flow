import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../services/revenuecat_service.dart';

class PricingScreen extends StatefulWidget {
  final SubscriptionService subscriptionService;
  final VoidCallback? onSubscriptionChanged;

  const PricingScreen({
    Key? key,
    required this.subscriptionService,
    this.onSubscriptionChanged,
  }) : super(key: key);

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isYearly = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentPlan = widget.subscriptionService.currentPlan;
    final isTrialing = widget.subscriptionService.currentSubscription?.status ==
        SubscriptionStatus.trialing;
    final trialDays = widget.subscriptionService.trialDaysRemaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Trial banner
            if (isTrialing && trialDays > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'re on a Free Trial!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$trialDays days remaining',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

            // Trial expired banner
            if (widget.subscriptionService.isTrialExpired)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Your Trial Has Expired',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Subscribe to continue using IrriTrack',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Billing toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton('Monthly', !_isYearly, () {
                    setState(() => _isYearly = false);
                  }),
                  _buildToggleButton('Yearly (Save 17%)', _isYearly, () {
                    setState(() => _isYearly = true);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan cards
            ...PlanDetails.allPlans
                .where((p) => p.plan != SubscriptionPlan.free)
                .map((plan) => _buildPlanCard(plan, currentPlan))
                .toList(),

            const SizedBox(height: 24),

            // Use RevenueCat Paywall (mobile only) - Native UI
            if (!kIsWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: _showRevenueCatPaywall,
                  icon: const Icon(Icons.storefront),
                  label: const Text('View Native Paywall'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),
              ),

            // Restore purchases (mobile only)
            if (!kIsWeb)
              TextButton(
                onPressed: _restorePurchases,
                child: const Text('Restore Purchases'),
              ),

            // Contact for enterprise
            const SizedBox(height: 16),
            const Text(
              'Need a custom solution?',
              style: TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () => _contactSales(),
              child: const Text('Contact Sales for Enterprise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.teal : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanDetails plan, PlanDetails? currentPlan) {
    final isCurrentPlan = currentPlan?.plan == plan.plan;
    final isPopular = plan.plan == SubscriptionPlan.team;
    final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final isEnterprise = plan.plan == SubscriptionPlan.enterprise;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? Colors.teal : Colors.grey.shade300,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 8)]
            : null,
      ),
      child: Column(
        children: [
          // Popular badge
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          plan.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isEnterprise) ...[
                          Text(
                            '\$${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isYearly ? '/year' : '/month',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ] else
                          const Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                _buildFeature(
                  Icons.people,
                  plan.hasUnlimitedUsers
                      ? 'Unlimited users'
                      : '${plan.maxUsers} user${plan.maxUsers > 1 ? 's' : ''}',
                ),
                _buildFeature(
                  Icons.home_work,
                  plan.hasUnlimitedProperties
                      ? 'Unlimited properties'
                      : '${plan.maxProperties} properties',
                ),
                if (plan.pdfReports)
                  _buildFeature(Icons.picture_as_pdf, 'PDF reports'),
                if (plan.cloudSync)
                  _buildFeature(Icons.cloud_sync, 'Cloud sync'),
                if (plan.prioritySupport)
                  _buildFeature(Icons.support_agent, 'Priority support'),
                if (plan.apiAccess)
                  _buildFeature(Icons.api, 'API access'),

                const SizedBox(height: 16),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan || _isLoading
                        ? null
                        : () => _subscribe(plan.plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.teal : null,
                      foregroundColor: isPopular ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isCurrentPlan
                                ? 'Current Plan'
                                : isEnterprise
                                    ? 'Contact Sales'
                                    : 'Subscribe',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan == SubscriptionPlan.enterprise) {
      _contactSales();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // Web: Use Stripe
        final checkoutUrl =
            await widget.subscriptionService.createStripeCheckoutSession(
          plan: plan,
          isYearly: _isYearly,
          successUrl: '${Uri.base.origin}/subscription-success',
          cancelUrl: '${Uri.base.origin}/pricing',
        );

        if (checkoutUrl != null) {
          await launchUrl(Uri.parse(checkoutUrl));
        } else {
          // For demo: manually set subscription
          await widget.subscriptionService.setSubscription(
            plan: plan,
            status: SubscriptionStatus.active,
            durationDays: _isYearly ? 365 : 30,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Subscribed to ${PlanDetails.getPlan(plan).name}!'),
                backgroundColor: Colors.green,
              ),
            );
            widget.onSubscriptionChanged?.call();
            Navigator.pop(context);
          }
        }
      } else {
        // Mobile: Use RevenueCat
        final success = await widget.subscriptionService.purchaseWithRevenueCat(
          plan,
          _isYearly,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscribed to ${PlanDetails.getPlan(plan).name}!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSubscriptionChanged?.call();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final restored = await widget.subscriptionService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Purchases restored successfully!'
                  : 'No purchases to restore',
            ),
            backgroundColor: restored ? Colors.green : Colors.orange,
          ),
        );

        if (restored) {
          widget.onSubscriptionChanged?.call();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _contactSales() {
    launchUrl(Uri.parse('mailto:sales@irritrack.com?subject=Enterprise%20Inquiry'));
  }

  /// Show RevenueCat native paywall (mobile only)
  Future<void> _showRevenueCatPaywall() async {
    setState(() => _isLoading = true);

    try {
      final result = await RevenueCatService.presentPaywall();

      if (mounted) {
        // Check if purchase was successful
        final isProUser = await RevenueCatService.isProUser();

        if (isProUser) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription activated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSubscriptionChanged?.call();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
