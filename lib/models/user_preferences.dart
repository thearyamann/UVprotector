class UserPreferences {
  final int skinTypeNumber;
  final int spf;

  const UserPreferences({
    required this.skinTypeNumber,
    required this.spf,
  });


  factory UserPreferences.defaults() => const UserPreferences(
    skinTypeNumber: 1,
    spf: 30,
  );
}