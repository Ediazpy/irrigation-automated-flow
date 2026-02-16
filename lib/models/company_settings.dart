class CompanySettings {
  final String companyName;
  final String companyPhone;
  final String companyEmail;
  final String companyAddress;
  final String? logoBase64;
  final String defaultTermsAndConditions;
  final int quoteExpirationDays;
  final String defaultFooterMessage;
  final bool photosRequired; // Manager toggle: require techs to take repair photos
  final String masterResetCode; // Master code for admin lockout recovery

  CompanySettings({
    required this.companyName,
    this.companyPhone = '',
    this.companyEmail = '',
    this.companyAddress = '',
    this.logoBase64,
    this.defaultTermsAndConditions = defaultTerms,
    this.quoteExpirationDays = 30,
    this.defaultFooterMessage = 'Thank you for your business!',
    this.photosRequired = false,
    this.masterResetCode = '',
  });

  static const String defaultTerms = '''
TERMS AND CONDITIONS

1. ACCEPTANCE: This quote is valid for the number of days specified above. Acceptance of this quote constitutes agreement to these terms.

2. PAYMENT: Payment is due upon completion of work unless other arrangements have been made in writing.

3. WARRANTY: All work performed is warranted for 90 days from completion date. Parts may carry manufacturer warranties.

4. SCOPE: This quote covers only the work specifically described. Additional work discovered during repairs may require a revised quote.

5. ACCESS: Client agrees to provide reasonable access to the property for scheduled work.

6. CANCELLATION: Cancellations must be made at least 24 hours in advance. Late cancellations may incur a service fee.

7. LIABILITY: We are not responsible for pre-existing conditions or damage caused by factors outside our control.
''';

  /// Full serialization for local storage (includes all fields)
  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'company_address': companyAddress,
      'logo_base64': logoBase64,
      'default_terms_and_conditions': defaultTermsAndConditions,
      'quote_expiration_days': quoteExpirationDays,
      'default_footer_message': defaultFooterMessage,
      'photos_required': photosRequired,
      'master_reset_code': masterResetCode,
    };
  }

  /// Firestore-safe serialization — excludes master_reset_code
  /// (master reset code is sensitive and only needed locally)
  Map<String, dynamic> toFirestoreJson() {
    return {
      'company_name': companyName,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'company_address': companyAddress,
      'logo_base64': logoBase64,
      'default_terms_and_conditions': defaultTermsAndConditions,
      'quote_expiration_days': quoteExpirationDays,
      'default_footer_message': defaultFooterMessage,
      'photos_required': photosRequired,
    };
  }

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      companyName: json['company_name'] ?? '',
      companyPhone: json['company_phone'] ?? '',
      companyEmail: json['company_email'] ?? '',
      companyAddress: json['company_address'] ?? '',
      logoBase64: json['logo_base64'],
      defaultTermsAndConditions: json['default_terms_and_conditions'] ?? defaultTerms,
      quoteExpirationDays: json['quote_expiration_days'] ?? 30,
      defaultFooterMessage: json['default_footer_message'] ?? 'Thank you for your business!',
      photosRequired: json['photos_required'] ?? false,
      masterResetCode: json['master_reset_code'] ?? '',
    );
  }

  CompanySettings copyWith({
    String? companyName,
    String? companyPhone,
    String? companyEmail,
    String? companyAddress,
    String? logoBase64,
    String? defaultTermsAndConditions,
    int? quoteExpirationDays,
    String? defaultFooterMessage,
    bool? photosRequired,
    String? masterResetCode,
  }) {
    return CompanySettings(
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyAddress: companyAddress ?? this.companyAddress,
      logoBase64: logoBase64 ?? this.logoBase64,
      defaultTermsAndConditions: defaultTermsAndConditions ?? this.defaultTermsAndConditions,
      quoteExpirationDays: quoteExpirationDays ?? this.quoteExpirationDays,
      defaultFooterMessage: defaultFooterMessage ?? this.defaultFooterMessage,
      photosRequired: photosRequired ?? this.photosRequired,
      masterResetCode: masterResetCode ?? this.masterResetCode,
    );
  }
}
