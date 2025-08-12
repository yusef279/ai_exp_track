class UserSettings {
  final String displayName;
  final String currency;          // e.g., "EGP"
  final double monthlyIncome;
  final double monthlyBudget;

  UserSettings({
    required this.displayName,
    required this.currency,
    required this.monthlyIncome,
    required this.monthlyBudget,
  });

  factory UserSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return UserSettings(
        displayName: '',
        currency: 'EGP',
        monthlyIncome: 0,
        monthlyBudget: 0,
      );
    }
    return UserSettings(
      displayName: (data['displayName'] ?? '') as String,
      currency: (data['currency'] ?? 'EGP') as String,
      monthlyIncome: (data['monthlyIncome'] ?? 0).toDouble(),
      monthlyBudget: (data['monthlyBudget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'currency': currency,
        'monthlyIncome': monthlyIncome,
        'monthlyBudget': monthlyBudget,
      };
}
