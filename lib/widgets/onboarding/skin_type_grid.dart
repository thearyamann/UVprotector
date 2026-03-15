import 'package:flutter/material.dart';
import '../../models/skin_type.dart';
import 'skin_type_card.dart';


class SkinTypeGrid extends StatelessWidget {
  final SkinType selectedType;
  final ValueChanged<SkinType> onSelected;

  const SkinTypeGrid({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Row(
          children: SkinType.all.take(3).map((s) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SkinTypeCard(
                skinType: s,
                isSelected: s.type == selectedType.type,
                onTap: () => onSelected(s),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
      
        Row(
          children: SkinType.all.skip(3).map((s) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SkinTypeCard(
                skinType: s,
                isSelected: s.type == selectedType.type,
                onTap: () => onSelected(s),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}