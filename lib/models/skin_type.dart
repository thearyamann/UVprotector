class SkinType {
  final int type;
  final String description;
  final int baseBurnTime;

  const SkinType._({
    required this.type,
    required this.description,
    required this.baseBurnTime,
  });

  static const SkinType type1 = SkinType._(
    type: 1,
    description: 'Very fair — always burns',
    baseBurnTime: 67,
  );
  static const SkinType type2 = SkinType._(
    type: 2,
    description: 'Fair — usually burns',
    baseBurnTime: 100,
  );
  static const SkinType type3 = SkinType._(
    type: 3,
    description: 'Medium — sometimes burns',
    baseBurnTime: 200,
  );
  static const SkinType type4 = SkinType._(
    type: 4,
    description: 'Olive — rarely burns',
    baseBurnTime: 300,
  );
  static const SkinType type5 = SkinType._(
    type: 5,
    description: 'Brown — very rarely burns',
    baseBurnTime: 400,
  );
  static const SkinType type6 = SkinType._(
    type: 6,
    description: 'Dark — almost never burns',
    baseBurnTime: 500,
  );

  static const List<SkinType> all = [type1, type2, type3, type4, type5, type6];

  static SkinType fromType(int type) {
    return all.firstWhere((s) => s.type == type, orElse: () => type1);
  }

  @override
  String toString() => 'SkinType($type: $description)';
}
