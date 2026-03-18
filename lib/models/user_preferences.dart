class UserPreferences {
  final String name;
  final int skinTypeNumber;
  final int spf;

  const UserPreferences({
    required this.name,
    required this.skinTypeNumber,
    required this.spf,
  });

  factory UserPreferences.defaults() => const UserPreferences(
    name: 'Friend',
    skinTypeNumber: 1,
    spf: 30,
  );
}