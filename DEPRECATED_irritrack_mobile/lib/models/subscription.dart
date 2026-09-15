/// Subscription plans available for IrriTrack
enum SubscriptionPlan {
  free,      // Trial/free tier
  solo,      // 1 user, basic features
  team,      // Up to 5 users
  business,  // Up to 15 users
  enterprise // Unlimited users
}

/// Subscription status
enum SubscriptionStatus {
  active,
  canceled,
  pastDue,
  trialing,
  expired,
  none
}

/// Subscription plan details and limits
class PlanDetails {
  final SubscriptionPlan plan;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int maxUsers;
  final int maxProperties;
  final bool pdfReports;
  final bool cloudSync;
  final bool prioritySupport;
  final bool apiAccess;

  const PlanDetails({
    required this.plan,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxUsers,
    required this.maxProperties,
    this.pdfReports = false,
    this.cloudSync = false,
    this.prioritySupport = false,
    this.apiAccess = false,
  });

  /// Get all available plans
  static List<PlanDetails> get allPlans => [
    const PlanDetails(
      plan: SubscriptionPlan.free,
      name: 'Free Trial',
      description: '14-day free trial with full features',
      monthlyPrice: 0,
      yearlyPrice: 0,
      maxUsers: 2,
      maxProperties: -1, // unlimited
      pdfReports: true,
      cloudSync: true,
    ),
    const PlanDetails(
      plan: SubscriptionPlan.solo,
      name: 'Solo',
      description: 'Perfect for individual contractors',
      monthlyPrice: 29,
      yearlyPrice: 290, // ~2 months free
      maxUsers: 1,
      maxProperties: -1, // unlimited
      pdfReports: true,
      cloudSync: true,
    ),
    const PlanDetails(
      plan: SubscriptionPlan.team,
      name: 'Team',
      description: 'For small irrigation businesses',
      monthlyPrice: 59,
      yearlyPrice: 590, // ~2 months free
      maxUsers: 5,
      maxProperties: -1, // unlimited
      pdfReports: true,
      cloudSync: true,
    ),
    const PlanDetails(
      plan: SubscriptionPlan.business,
      name: 'Business',
      description: 'For growing companies',
      monthlyPrice: 99,
      yearlyPrice: 990, // ~2 months free
      maxUsers: 15,
      maxProperties: -1, // unlimited
      pdfReports: true,
      cloudSync: true,
      prioritySupport: true,
    ),
    const PlanDetails(
      plan: SubscriptionPlan.enterprise,
      name: 'Enterprise',
      description: 'Custom solutions for large organizations',
      monthlyPrice: -1, // Contact sales
      yearlyPrice: -1,
      maxUsers: -1, // unlimited
      maxProperties: -1, // unlimited
      pdfReports: true,
      cloudSync: true,
      prioritySupport: true,
      apiAccess: true,
    ),
  ];

  /// Get plan details by plan type
  static PlanDetails getPlan(SubscriptionPlan plan) {
    return allPlans.firstWhere(
      (p) => p.plan == plan,
      orElse: () => allPlans.first,
    );
  }

  /// Format price for display
  String get monthlyPriceDisplay {
    if (monthlyPrice < 0) return 'Contact Sales';
    if (monthlyPrice == 0) return 'Free';
    return '\$${monthlyPrice.toStringAsFixed(0)}/mo';
  }

  String get yearlyPriceDisplay {
    if (yearlyPrice < 0) return 'Contact Sales';
    if (yearlyPrice == 0) return 'Free';
    return '\$${yearlyPrice.toStringAsFixed(0)}/yr';
  }

  /// Check if a limit is unlimited
  bool get hasUnlimitedUsers => maxUsers < 0;
  bool get hasUnlimitedProperties => maxProperties < 0;
}

/// User's subscription information
class Subscription {
  final String id;
  final String customerId; // Stripe customer ID or RevenueCat user ID
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool isYearly;
  final String? stripeSubscriptionId;
  final String? revenueCatEntitlementId;
  final DateTime lastUpdated;

  Subscription({
    required this.id,
    required this.customerId,
    required this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    this.trialEndDate,
    this.isYearly = false,
    this.stripeSubscriptionId,
    this.revenueCatEntitlementId,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Create a free/trial subscription
  factory Subscription.trial({required String customerId}) {
    final now = DateTime.now();
    return Subscription(
      id: 'trial_${now.millisecondsSinceEpoch}',
      customerId: customerId,
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.trialing,
      startDate: now,
      trialEndDate: now.add(const Duration(days: 14)),
      endDate: now.add(const Duration(days: 14)),
    );
  }

  /// Create an empty/no subscription
  factory Subscription.none({required String customerId}) {
    return Subscription(
      id: 'none',
      customerId: customerId,
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.none,
    );
  }

  /// Check if subscription is valid (active or trialing)
  bool get isValid {
    if (status == SubscriptionStatus.active) return true;
    if (status == SubscriptionStatus.trialing) {
      return trialEndDate != null && DateTime.now().isBefore(trialEndDate!);
    }
    return false;
  }

  /// Check if trial has expired
  bool get isTrialExpired {
    if (status != SubscriptionStatus.trialing) return false;
    return trialEndDate != null && DateTime.now().isAfter(trialEndDate!);
  }

  /// Days remaining in trial
  int get trialDaysRemaining {
    if (trialEndDate == null) return 0;
    final diff = trialEndDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Get plan details for this subscription
  PlanDetails get planDetails => PlanDetails.getPlan(plan);

  /// Check if user count is within limit
  bool canAddUser(int currentUserCount) {
    if (planDetails.hasUnlimitedUsers) return true;
    return currentUserCount < planDetails.maxUsers;
  }

  /// Check if property count is within limit
  bool canAddProperty(int currentPropertyCount) {
    if (planDetails.hasUnlimitedProperties) return true;
    return currentPropertyCount < planDetails.maxProperties;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'plan': plan.name,
      'status': status.name,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'trial_end_date': trialEndDate?.toIso8601String(),
      'is_yearly': isYearly,
      'stripe_subscription_id': stripeSubscriptionId,
      'revenuecat_entitlement_id': revenueCatEntitlementId,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      plan: SubscriptionPlan.values.firstWhere(
        (p) => p.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SubscriptionStatus.none,
      ),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      trialEndDate: json['trial_end_date'] != null
          ? DateTime.parse(json['trial_end_date'])
          : null,
      isYearly: json['is_yearly'] ?? false,
      stripeSubscriptionId: json['stripe_subscription_id'],
      revenueCatEntitlementId: json['revenuecat_entitlement_id'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }

  Subscription copyWith({
    String? id,
    String? customerId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    bool? isYearly,
    String? stripeSubscriptionId,
    String? revenueCatEntitlementId,
  }) {
    return Subscription(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      isYearly: isYearly ?? this.isYearly,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      revenueCatEntitlementId: revenueCatEntitlementId ?? this.revenueCatEntitlementId,
    );
  }
}
