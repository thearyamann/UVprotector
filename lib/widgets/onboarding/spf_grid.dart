import 'package:flutter/material.dart';
import 'spf_card.dart';


class SpfGrid extends StatelessWidget {
  final int selectedSpf;
  final ValueChanged<int> onSelected;

  const SpfGrid({
    super.key,
    required this.selectedSpf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = SpfOption.all;

    return Column(
      children: [

        Row(
          children: options.take(2).map((o) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SpfCard(
                option: o,
                isSelected: o.value == selectedSpf,
                onTap: () => onSelected(o.value),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),

        Row(
          children: options.skip(2).map((o) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SpfCard(
                option: o,
                isSelected: o.value == selectedSpf,
                onTap: () => onSelected(o.value),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}