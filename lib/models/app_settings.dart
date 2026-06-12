class AppSettings {
  const AppSettings({
    this.aiConsentGiven,
    this.educationalDisclaimerAccepted = false,
    this.dataSourceAttributionAccepted = false,
  });

  final bool? aiConsentGiven;
  final bool educationalDisclaimerAccepted;
  final bool dataSourceAttributionAccepted;

  factory AppSettings.defaults() {
    return const AppSettings(aiConsentGiven: null);
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      aiConsentGiven: json.containsKey('aiConsentGiven')
          ? json['aiConsentGiven'] as bool?
          : null,
      educationalDisclaimerAccepted:
          json['educationalDisclaimerAccepted'] as bool? ?? false,
      dataSourceAttributionAccepted:
          json['dataSourceAttributionAccepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aiConsentGiven': aiConsentGiven,
      'educationalDisclaimerAccepted': educationalDisclaimerAccepted,
      'dataSourceAttributionAccepted': dataSourceAttributionAccepted,
    };
  }

  AppSettings copyWith({
    bool? aiConsentGiven,
    bool? educationalDisclaimerAccepted,
    bool? dataSourceAttributionAccepted,
    bool clearAiConsent = false,
  }) {
    return AppSettings(
      aiConsentGiven:
          clearAiConsent ? null : aiConsentGiven ?? this.aiConsentGiven,
      educationalDisclaimerAccepted: educationalDisclaimerAccepted ??
          this.educationalDisclaimerAccepted,
      dataSourceAttributionAccepted:
          dataSourceAttributionAccepted ?? this.dataSourceAttributionAccepted,
    );
  }
}
